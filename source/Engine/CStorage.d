module Engine.CStorage;

import std.traits;
import Engine.util;
import std.stdio;

class ComponentStorage {
	package static __gshared ComponentStorage[TypeInfo] Storages;

	public static ComponentStorage get(T)() {
		return Storages[typeid(T)];
	}

	public T FindFunction(T)(string name) {
		static if (isSomeFunction!T) {
			static if (is(T == delegate)) {
				T t;
				t.funcptr = cast(typeof(t.funcptr))FindFunction(name,typeid(t.funcptr));
				return t;
			} else {
				return cast(T)FindFunction(name,typeid(T));
			}
		}
		assert(0, "T is not function");
	}

	public bool FindFunction(T)(auto ref T t, string name) {
		static if (isSomeFunction!T) {
			static if (is(T == delegate)) {
				t.funcptr = cast(typeof(t.funcptr))FindFunction(name,typeid(t.funcptr));
				return t is null;
			} else {
				t = FindFunction(name,typeid(T));
				return t is null;
			}
		}
		assert(0, "T is not function");
	}

	abstract void*[] Components();
	abstract void* FindFunction(string name, TypeInfo type);
}

class StorageImpl(T) : ComponentStorage {
	static if (is(T == class)) {
		enum size = __traits(classInstanceSize, T);
		alias Tp = T;
	}
	else { 
		enum size = T.sizeof;
		alias Tp = T*;
	}

	public static __gshared Tp[] storage = new Tp[0]; 
	public static __gshared StorageImpl!T it = new StorageImpl!T();
	package static __gshared T sample;

	static this() {
		sample = T.init;
		ComponentStorage.Storages[typeid(T)] = it;
	}	

	public static Tp allocate(Args...)(Args args) {
		auto obj = new T(args);
		storage.length++;
		storage[storage.length-1] = obj;
		return obj;
	}

	template ID(T...){alias    T ID;}

	public override void* FindFunction(string name, TypeInfo type) {
		return _FindFunction(name, type);
	}

	package static void* _FindFunction(string name, TypeInfo type) {
		foreach (member_string ; __traits(allMembers, T))
		{
			if (name == member_string) {
				foreach(overload; __traits(getOverloads, T, member_string)) {
					static if (__traits(compiles, &overload)) {
						if (typeid(&overload) == type)
							return cast(void*)&overload;
					}
				}
			}
		}	
		return null;
	}


	public override void*[] Components() {
		return cast(void*[])storage;
	}
}
