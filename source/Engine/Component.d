module Engine.Component;


import t = Engine.Transform;
import std.traits;
import e = Engine.Entity;
import std.traits;
import std.typetuple;
import Engine.CStorage;
import Engine.util;

class Component {
	package void* component;
	package TypeInfo type;
	package ComponentStorage storage;

	this(T)(T t)  {
		component = cast(void*)t;
		static if (is(T == class)) {
			type = typeid(T);
			storage = StorageImpl!T.it;
		}
		else {
			alias U = baseType!T;
			type = typeid(U);
			storage = StorageImpl!U.it;
		}
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