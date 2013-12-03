module Engine.math;

public import gl3n.linalg;
import std.traits;

struct dirty(T) {
	bool dirty = true;
	T val;

	alias val this;	

	this(T v) {
		val = v;
	}

	@property opDispatch(string s, Args...)(Args args) {
		static if (mixin("isSomeFunction!(T."~s~")")) {
			static if(mixin("isFuncMutable!(T."~s~")") && !mixin("functionAttributes!(T."~s~") & FunctionAttribute.property")) {
				dirty = true;
			}
			static if (mixin("is(ReturnType!(T."~s~") == void)")) {
				mixin("val." ~ s ~ "(args);");
			} else {
				static if (args.length > 0 && mixin("functionAttributes!(T."~s~") & FunctionAttribute.property")) {
					dirty = true;
					mixin("val." ~ s ~ " = cast(typeof(val." ~ s ~"))args[0];");
				} else {
					return mixin("val." ~ s ~ "(args)");
				}
			}
		} else {
			static if(args.length > 0) {
				dirty = true;
				mixin("val." ~ s ~ " = cast(typeof(val." ~ s  ~ "))args[0];");
			} else {
				return mixin("val." ~ s);
			}
		}
	}

	void opOpAssign(string op, R)(R r) {
		dirty = true;
		mixin("val" ~ op ~ "= r;");
	}

	void opAssign(R)(auto ref const R r) {
		static if (__traits(compiles, val.opAssign!R(r))) {
			val.opAssign!R(r);
		} else {
			val = r;
		}
		dirty = true;
	}

	T opUnary(string s)() {
		dirty = true;
		return mixin(s ~ "val");
	}
}

template isFuncMutable(T...) if (T.length == 1)
{
	enum bool isFuncMutable = !(is(typeof(T[0]) == const) || is(typeof(T[0]) == immutable));
}


alias Rect!(int) recti;
alias Rect!(float) rect;

struct Rect(T) {
	alias Vector!(T, 2) vectp;
	vectp min = vectp(0,0);
	vectp max = vectp(0,0);

	static Rect Zero = Rect();


	this(T width, T height) {
		max = vectp(width,height);
	}

	void add(vectp v) {
		min += v;
		max += v;
	}

	nothrow this(vectp min, vectp max) {
		this.min = min;
		this.max = max;
	}

	// Empty returns whether the rectangle contains no points.
	nothrow pure bool Empty()() const  {
		return min.x >= max.x || min.y >= max.y;
	}

	nothrow pure T Dx()() const  {
		return max.x - min.x;
	}

	nothrow pure T Dy()() const  {
		return max.y - min.y;
	}

	nothrow pure bool In()(Rect s) const   {
		if (Empty()) {
			return true;
		}
		// Note that r.Max is an exclusive bound for r, so that this.In(s)
		// does not require that this.max.In(s).
		return s.min.x <= min.x && max.x <= s.max.x &&
			s.min.y <= min.y && max.y <= s.max.y;
	}

	//returns an AABB that holds both a and b.
	public static nothrow Rect!T  Merge()(auto ref const Rect!T a,auto ref const Rect!T b ) {
		return Rect!T(
				  minv(a.min, b.min),
				  maxv(a.max, b.max),
				  );
	}	

	T Area()() {
        return (max.x - min.x) * (max.y - min.y);
	}

	static T  MergedArea()(auto ref const Rect!T a,auto ref const Rect!T b ) {
        return (maxv(a.max.x, b.max.x) - minv(a.min.x, b.min.x)) * (maxv(a.max.y, b.max.y) - minv(a.min.y, b.min.y));
	}

	static T Proximity()(auto ref const Rect!T a,auto ref const Rect!T b ) {
        return abs(a.min.x+a.max.x-b.min.x-b.max.x) + abs(a.min.y+a.max.y-b.min.y-b.max.y);
	}

	static bool Intersects()(auto ref const Rect!T a,auto ref const Rect!T b ) {
        return (a.min.x <= b.max.x && b.min.x <= a.max.x && a.min.y <= b.max.y && b.min.y <= a.max.y);
	}

	static bool Contains()(auto ref const Rect!T aabb,auto ref const Rect!T other ) {
        return aabb.min.x <= other.min.x &&
			aabb.max.x >= other.max.x &&
			aabb.min.y <= other.min.y &&
			aabb.max.y >= other.max.y;
	}


	nothrow static T abs()(T v)  {
		if (v > 0)
			return v;
		return -v;
	}

	nothrow static T minv()(T v1,T v2)  {
		if (v1 > v2)
			return v2;
		return v1;
	}

	nothrow static T maxv()(T v1,T v2)  {
		if (v1 > v2)
			return v1;
		return v2;
	}


	nothrow static vectp minv()(vectp v1,vectp v2)  {
		vectp o;
		if (v1.x < v2.x) {
			o.x = v1.x;
		} else {
			o.x = v2.x;
		}

		if (v1.y < v2.y) {
			o.y = v1.y;
		} else {
			o.y = v2.y;
		}
		return o;
	}

	nothrow static vectp maxv()(vectp v1,vectp v2)  {
		vectp o;
		if (v1.x > v2.x) {
			o.x = v1.x;
		} else {
			o.x = v2.x;
		}

		if (v1.y > v2.y) {
			o.y = v1.y;
		} else {
			o.y = v2.y;
		}
		return o;
	}
}