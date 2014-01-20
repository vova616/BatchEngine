module Engine.util;

import std.range;
import std.parallelism;

package extern (C) Object _d_newclass (in ClassInfo info);

T copy(T:Object) (T value)
{
	if (value is null)
		return null;
	auto size = value.classinfo.init.length;	
	Object v = cast(Object) ( (cast(void*)value) [0..size].dup.ptr );
	v.__monitor = null;
	return cast (T)v;
}

T copy2(T:Object) (T value)
{
	if (value is null)
		return null;
	void *c = cast(void*)_d_newclass (value.classinfo);
	size_t size = value.classinfo.init.length;
	c[0..size] = (cast (void *) value)[0..size];
	(cast(Object)c).__monitor = null;
	return cast (T)c;
}


package Object newInstance (in ClassInfo classInfo)
{
	return _d_newclass(classInfo);
}

template remove(ArrTy, IntTy) {
	static assert(is(IntTy : int));
	void remove(ArrTy arr, IntTy ix) {
		arr[ix] = arr[$-1];
		arr.length = arr.length - 1;
	}
}

template baseType(T : T*) {
	static if (!is(baseType!T == T)) {
		alias baseType = baseType!T;
	} else {
		alias baseType = T;
	}
}

template baseType(T) {
	alias baseType = T;
}

template pointerType(T) {
	alias Tp = baseType!T;
	static if (is(Tp == class)) {
		alias pointerType = Tp;
	}
	else { 
		alias pointerType = Tp*;
	}
}   

unittest {
	class A {

	}
	struct B {

	}
	assert(is(baseType!A == A));
	assert(is(baseType!(A*) == A));
	assert(is(baseType!(A**) == A));
	assert(is(baseType!(A***) == A));
	
	assert(is(baseType!B == B));
	assert(is(baseType!(B*) == B));
	assert(is(baseType!(B**) == B));
	assert(is(baseType!(B***) == B));
	
	assert(is(pointerType!B == B*));
	assert(is(pointerType!(B*) == B*));
	assert(is(pointerType!(B**) == B*));
	assert(is(pointerType!(B***) == B*));

	assert(is(pointerType!A == A));
	assert(is(pointerType!(A*) == A));
	assert(is(pointerType!(A**) == A));
	assert(is(pointerType!(A***) == A));
}

void parallelRange(int works, T, R)(T t, R range) {
	typeof(scopedTask(t,range))[works] tasks;
	int m = range.length/(tasks.length+1);
	for (int i=0;i<tasks.length;i++) {
		tasks[i] = scopedTask(t,range[i*m..(i+1)*m]);
		taskPool.put(tasks[i]);
	}
	t(range[(tasks.length)*m..range.length]);
}

struct ConstArray(T) {
	package T[] array;

	this(T[] array) {
		this.array = array;
	}

	@property length() { return array.length; }

	T opIndex(size_t i) {
		return array[i];
	}

	auto opSlice(size_t x, size_t y) {
		return typeof(this)(array[x..y]);
	}	

	@property front() { return array.front; }
	@property back() { return array.back; }
	@property empty() const {return array.empty;}
	void popFront() {assert(!empty); array.popFront();}
	void popBack() {assert(!empty); array.popBack();}
	@property typeof(this) save() {return typeof(this)(array);}
	
	static assert(isForwardRange!(typeof(this)));
	static assert(hasLength!(typeof(this)));
	static assert(isRandomAccessRange!(typeof(this)));
}