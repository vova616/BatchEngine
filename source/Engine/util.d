module Engine.util;

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