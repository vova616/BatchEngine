module Engine.Entity;

import Engine.Component;
import t = Engine.Transform;
import Engine.Core;
import Engine.Coroutine;
import std.stdio;
import Engine.Sprite;
import Engine.util;

class Entity
{
	package Component[] components;
	package t.Transform transform_;
	package size_t arrayIndex;
	bool active;
	Sprite sprite;
	string name;
	bool valid;
	
	@property package bool inScene() {
		return arrayIndex >= 0;
	};

	this()
	{
		components = new Component[5];
		components.length = 0;
		AddComponent(new t.Transform());
		active = true;
		valid = true;
		arrayIndex = -1;
	}

	final @property t.Transform transform() { return transform_; }

	final @property public const(Component[]) Components() {
			return cast(const)components;	
		};

		/*
	public void AddComponent()(Component component) {
		components ~= component;
		component.onComponentAdd(this);
	}
		*/
		
	public T AddComponent(T : Component)(T t) {
		components ~= t;
		(cast(Component)t).bind(this);
		t.OnComponentAdd();
		return t;
	}


	public T AddComponent(T : Component, Args...)(Args args) {
		auto t = new ComponentImpl!(T)(args);
		components ~= t;
		t.bind(this);
		t.OnComponentAdd();
		return t.component;
	}


	public T* AddComponent(T, Args...)(Args args) {
		auto t = new ComponentImpl!(T)(args);
		components ~= t;
		t.bind(this);
		t.OnComponentAdd();
		return &t.component;
	}
	
	public T GetComponent(T)() {
		foreach( c; components) {
			T t = c.Cast!T();
			if (t !is null) {
				return t;
			}
		}
		return null;
	}
	
	public T GetComponent(T)(T component)  {
		foreach( c; components) {
			T t = c.Cast!T();
			if (t !is null) {
				return t;
			}
		}
		return null;
	}

	public Entity Clone()
	{
		Entity t = new Entity();
		foreach (ref c ; this.components) {
			auto newC = c.copy();
			t.AddComponent(newC);
		}
		return t;
	}

	public void Destory()
	{
		active = false;
		valid = false;
		Core.RemoveEntity(this);
	}


	
	public bool RemoveComponent()(Component component) {
		for (int i=0;i<components.length;i++) {
			if (component == components[i]) {
				components[i] = components[components.length-1];
				components.length--;
				return true;
			}
		}
		return false;
	}

	public bool RemoveComponent(T)() {
		bool result = false;
		for (int i=0;i<components.length;i++) {
			T t = cast(T)components[i];
			if (t !is null) {
				components[i] = components[components.length-1];
				components.length--;
				i--;
				result = true;
			}
		}
		return result;
	}
}
	

