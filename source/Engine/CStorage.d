module Engine.CStorage;

import std.traits;
import Engine.util;
import std.stdio;
import std.typetuple;
import Engine.Entity;

class ComponentStorage {
	package static __gshared ComponentStorage[TypeInfo] Storages;

	public static ComponentStorage get(T)() {
		return StorageImpl!(baseType!T).it;
	}

	public static ComponentStorage[] getDeep(T)() {
		ComponentStorage[] storages = null;
		foreach (s; Storages.values) {
			void* dummy = cast(void*)1;
			if (cast(void*)s.Cast!T(dummy) == cast(void*)1) {
				storages ~= s;
			}
		}	
		return storages;
	}

	public static ConstArray!(pointerType!T) components(T)() {
		return ConstArray!(pointerType!T)(StorageImpl!(baseType!T).active);
	}	
	
	public static ConstArray!(pointerType!T)[] componentsDeep(T)() {
		alias U = pointerType!T;
		static if (is(T == struct)) {
			//struct cannot have/be inhereted.
			return [ components!T() ];
		} else {	
			ConstArray!(U)[] comps = null;
			foreach (s; Storages.values) {
				void* dummy = cast(void*)1;
				//checking if its possible to cast the value to T.
				if (cast(void*)s.Cast!T(dummy) !is null) {	
					comps ~= cast(ConstArray!U)s.Components();
				}
			}		
			return comps;
		}
	}
	
	public static ConstArray!(ComponentStorage) all()() {
		return ConstArray!(ComponentStorage)(Storages.values);
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
	
	public auto Cast(T)(void* component)  {
		return cast(pointerType!T)TypeCast(typeid(pointerType!T), component);
	}	
	
	abstract TypeInfo Type();
	abstract void* TypeCast(TypeInfo type, void* component);
	abstract ConstArray!(void*) Components();
	abstract void* FindFunctionType(string name, TypeInfo type);
	abstract void* Clone(void*);
	abstract void Bind(void*,Entity);
	abstract void Active(void*);
	abstract void Deactive(void*);
	abstract void Remove(void*);
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

	package struct EPair {
		Entity entity;
		size_t index;
		bool active;
	}	

	package static __gshared Tp[] storage; 
	package static __gshared size_t activeIndex = 0;
	package static __gshared EPair[Tp] map;

	public static __gshared StorageImpl!T it = new StorageImpl!T();
	package static __gshared bool added = false;	
	
	public static Tp allocate(Args...)(Args args) {
		if (!added) {
			added = true;
			ComponentStorage.Storages[typeid(T)] = it;
		}
		return new T(args);
	}
	
	public override TypeInfo Type() {
		return typeid(T);
	}	
	
	public override void Bind(void* component, Entity entity) {
		Bind(cast(Tp)component, entity);
	}

	@property final public static Tp[] active() {
		return storage[0..activeIndex];	
	};	

	public static void Bind(Tp component, Entity entity) {
		storage ~= component;
		map[component] = EPair(entity,storage.length-1,false);
		static if (__traits(compiles, component._entity = entity)) {
			component._entity = entity;
		}	
		static if (__traits(compiles, component.OnComponentAdd())) {
			component.OnComponentAdd();
		}
	}

	public override void Active(void* component) {
		Active(cast(Tp)component);
	}

	public override void Deactive(void* component) {
		Deactive(cast(Tp)component);
	}

	public override void Remove(void* component) {
		Remove(cast(Tp)component);
	}

	public static void Active(Tp component) {
		auto epair = &map[component];
		assert (!epair.active);
		auto index = activeIndex;
		//Check if we are activating the last index
		if (epair.index == index) {
			activeIndex++;
			epair.active = true;
		} else {
			//get first deactived component
			auto component2 = storage[index];
			auto epair2 = &map[component2];
			assert (!epair2.active);
			//replace first deactived with the activated component
			storage[index] = component;
			storage[epair.index] = component2;
			//replace indecies and change active to true
			epair2.index = epair.index;
			epair.index = index;
			epair.active = true;
			//we added an active component
			activeIndex++;
		}	
	}
	
	public static void Deactive(Tp component) {
		auto epair = &map[component];
		assert (epair.active);
		auto index = activeIndex-1;
		//Check if we are deactivating the last index
		if (epair.index == index) {
			activeIndex--;	
			epair.active = false;
		} else {
			//get last active component
			auto component2 = storage[index];
			auto epair2 = &map[component2];
			assert (epair2.active);
			//replace last active with the deactivated component
			storage[index] = component;
			storage[epair.index] = component2;
			//replace indecies and change active to false
			epair2.index = epair.index;
			epair.index = index;
			epair.active = false;
			//we removed an active component
			activeIndex--;
		}	
	}
	
	public static void Remove(Tp component) {
		auto epair = map[component];
		map.remove(component);
		if (epair.index != storage.length-1) {
			auto dstIndex = epair.index;
			auto srcIndex = activeIndex-1;
			if (epair.active && activeIndex != storage.length) {
				//Replace with last active	
				if (dstIndex != srcIndex) {
					auto component2 = storage[srcIndex];
					auto epair2 = &map[component2];
					epair2.index = dstIndex;
					assert (epair2.active);
					storage[dstIndex] = component2;
					dstIndex = srcIndex;
				}			
			}	
			srcIndex = storage.length-1;
			//Replace with the last element
			auto component2 = storage[srcIndex];
			auto epair2 = &map[component2];
			epair2.index = dstIndex;
			storage[dstIndex] = component2;
		}
		if (epair.active) {
			activeIndex--;
		}
		storage.length--;
	}
	
	public static Tp Clone(Tp component) {
		auto c = (cast(void*)component)[0..size].dup.ptr;
		static if (is(T == class)) {
			(cast(Object)c).__monitor = null;
		}
		return cast(Tp)c;
	}

	public override void* Clone(void* component) {
		return cast(void*)Clone(cast(Tp)component);
	}
	
	public override void* FindFunctionType(string name, TypeInfo type) {
		return _FindFunctionType(name, type);
	}
	
	package static void* _FindFunctionType(string name, TypeInfo type) {
		foreach (member_string ; __traits(allMembers, T))
		{
			static if (__traits(compiles, __traits(getMember, T, member_string)))
			{
				bool found = false;
				foreach(overload; __traits(getOverloads, T, member_string)) {
					static if (__traits(compiles, &overload)) {
						if (!found) {
							if (name == member_string) {
								found = true;
							} else {
								break;
							}
						}
						if (typeid(&overload) == type)
							return cast(void*)&overload;
					}
				}
			}

		}	
		return null;
	}

	public override void* TypeCast(TypeInfo type, void* component) {
		static if (is(T == class))
			return _Cast(type, component);
		else {
			if (type == typeid(Tp))
				return cast(Tp)component;
			return null;	
		}
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
			return cast(void*)cast(F)(cast(T)component);
		}
		return null;
	}

	
	public override ConstArray!(void*) Components() {
		return ConstArray!(void*)(cast(void*[])active);
	}
}