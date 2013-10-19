module Engine.math;

public import gl3n.linalg;

alias Rect!(int) recti;
alias Rect!(float) rect;

struct Rect(T) {
	alias Vector!(T, 2) vectp;
	vectp min;
	vectp max;

	static Rect Zero = Rect();


	this(T width, T height) {
		max = vectp(width,height);
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