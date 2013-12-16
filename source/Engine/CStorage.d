module Engine.CStorage;

import std.traits;
import Engine.util;
import std.stdio;
import std.typetuple;
import e = Engine.Entity;
import t = Engine.Transform;

class Component {
	void* component;
	TypeInfo type;
	ComponentStorage storage;

	this(T)(T t) {
		component = cast(void*)t;
		type = typeid(T);
		storage = StorageImpl!T.it;
	}

	this()(void* component, ComponentStorage storage) {
		this.component = component;
		this.storage = storage;
		this.type = storage.Type();
	}

	public ReturnType!T RunFunction(T,Args...)(string name, Args args) {
		auto func = FindFunction!T(name);
		if (func is null)
			return;
		static if (is(T == delegate)) {
			func.ptr = component;
			return func(args);
		} else {
			return func(args);
		}
	}

	public T FindFunction(T)(string name) {
		auto fnc = storage.FindFunction!T(name);
		static if (is(T == delegate)) {
			if (fnc is null)
				return null;
			fnc.ptr = component;
		}
		return fnc;
	}
	
	public bool FindFunction(T)(auto ref T t, string name) {
		auto found = storage.FindFunction(t,name);
		static if (is(T == delegate)) {
			if (!found)
				return false;
			t.ptr = component;
		}
		return found;
	}
	
	public T Cast(T)() if (is(T == class)) {
		return storage.Cast!T(component);
	}	
	
	public T* Cast(T)() if (is(T == struct)) {
		return storage.Cast!T(component);
	}	
	
	public T* Cast(T : T*)(v) if (is(T == struct)) {
		return storage.Cast!T(component);
	}		
}

template ComponentBase()
{
	public e.Entity _entity;
	
	final @property public e.Entity entity() {
		return _entity;	
	};
	
	final @property public t.Transform transform() {
		return entity.transform;
	};
}

class ComponentStorage {
	package static __gshared ComponentStorage[TypeInfo] Storages;

	public static ComponentStorage get(T)() {
		return Storages[typeid(T)];
	}

	public static ComponentStorage[] getAll()() {
		return Storages.values;
	}
	
	public void RunFunction(T,Args...)(string name, Args args) {
		auto func = FindFunction!T(name);
		if (func is null)
			return;
		static if (is(T == delegate)) {
			auto comps = Components();
			foreach (c; comps) {
				func.ptr = c;
				func(args);
			}
		} else {
			func(args);
		}
	}

	public T FindFunction(T)(string name) {
		static if (isSomeFunction!T) {
			static if (is(T == delegate)) {
				T t;
				t.funcptr = cast(typeof(t.funcptr))FindFunctionType(name,typeid(t.funcptr));
				return t;
			} else {
				return cast(T)FindFunctionType(name,typeid(T));
			}
		}
		assert(0, "T is not function");
	}

	public bool FindFunction(T)(auto ref T t, string name) {
		static if (isSomeFunction!T) {
			static if (is(T == delegate)) {
				t.funcptr = cast(typeof(t.funcptr))FindFunctionType(name,typeid(t.funcptr));
				return t is null;
			} else {
				t = FindFunctionType(name,typeid(T));
				return t is null;
			}
		}
		assert(0, "T is not function");
	}
		
	public T Cast(T)(void* component) if (is(T == class)) {
		return cast(T)TypeCast(typeid(T), component);
	}	

	public T* Cast(T)(void* component) if (is(T == struct)) {
		return cast(T*)TypeCast(typeid(T*), component);
	}	
			
	public T* Cast(T : T*)(void* component) if (is(T == struct)) {
		return cast(T*)TypeCast(typeid(T*), component);
	}		
	
	abstract TypeInfo Type();
	abstract void* TypeCast(TypeInfo type, void* component);
	abstract void*[] Components();
	abstract void* FindFunctionType(string name, TypeInfo type);
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
	package static __gshared bool added = false;	
	

	public static Tp allocate(Args...)(Args args) {
		if (!added) {
			added = true;
			ComponentStorage.Storages[typeid(T)] = it;
		}
		auto obj = new T(args);
		storage.length++;
		storage[storage.length-1] = obj;
		return obj;
	}

	public override TypeInfo Type() {
		return typeid(T);
	}	
			
	public override void* FindFunctionType(string name, TypeInfo type) {
		return _FindFunctionType(name, type);
	}
	
	package static void* _FindFunctionType(string name, TypeInfo type) {
		foreach (member_string ; __traits(allMembers, T))
		{
			static if (__traits(compiles, __traits(getMember, T, member_string)))
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

	static if (is(T == struct)) 
	public override void* TypeCast(TypeInfo type, void* component) {
		if (type == typeid(Tp))
			return cast(Tp)component;
		return null;	
	}

	static if (is(T == class))
	public override void* TypeCast(TypeInfo type, void* component) {
		return _Cast(type, component);
	}

	static if (is(T == class))
	package static void* _Cast(TypeInfo type, void* component)
	{
		alias TypeTuple!(T, ImplicitConversionTargets!T) AllTypes;
		foreach (F ; AllTypes)
		{
			if (type != typeid(F) &&
			    type != typeid(const(F)))
			{ 
				static if (isImplicitlyConvertible!(F, immutable(F)))
				{
					if (type != typeid(immutable(F)))
					{
						continue;
					}
				}
				else
				{
					continue;
				}
			}
			return cast(void*)cast(F)component;
		}
		return null;
	}


	public override void*[] Components() {
		return cast(void*[])storage;
	}
}