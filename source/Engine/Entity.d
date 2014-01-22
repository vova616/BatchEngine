module Engine.Entity;

import Engine.Component;
import t = Engine.Transform;
import Engine.Core;
import Engine.Coroutine;
import std.stdio;
import Engine.Sprite;
import Engine.util;
import Engine.CStorage;

class Entity
{
	package Component[] components;
	package t.Transform transform_;
	package ptrdiff_t arrayIndex;
	bool active;
	Sprite sprite;
	string name;
	bool valid;
	
	@property package bool inScene() {
		return arrayIndex >= 0;
	};

	this(bool addTransform = true)
	{
		components = new Component[5];
		components.length = 0;
		if (addTransform)
			AddComponent!(t.Transform)();
		active = true;
		valid = true;
		arrayIndex = -1;
	}

	final @property t.Transform transform() { return transform_; }

	final @property public auto Components() {
		return ConstArray!Component(components);	
	};
	
	public void SendMessage(string op, void* arg) {
		//foreach( c; components) {
		//	c.OnMessage(op, arg);
		//}
	}

	public auto AddComponent(T, Args...)(Args args)  {
		auto t = StorageImpl!(T).allocate(args);
		components ~= new Component(t);
		StorageImpl!(T).Bind(t,this);	
		return t;	
	}	

	public auto AddComponent()(Component component)  {
		components ~= component;
		component.storage.Bind(component.component,this);
		return component;
	}	

	public auto AddComponent(T)(T component) if (!is(T == Component))  {
		auto c = new Component(component);
		components ~= c;
		c.storage.Bind(c.component,this);
		return component;
	}

	public auto GetComponent(T)() {
		alias Tp = pointerType!T;
		foreach( c; components) {
			auto t = c.Cast!Tp();
			if (t !is null) {
				return t;
			}
		}
		return null;
	}

	public Entity Clone()
	{		
		Entity t = new Entity(false);
		foreach (ref c ; this.components) {
			t.AddComponent(c.Clone());
		}
		return t;
	}

	public void Destory()
	{
		if (!valid)
			return;
		Core.RemoveEntity(this);
		foreach( c; components) {	
			c.storage.Remove(c.component);
		}
		components = null;
		active = false;
		valid = false;
	}

	package void onActive() {
		foreach( c; components) {
			c.storage.Active(c.component);
		}
	}
	

	public bool RemoveComponent()(Component component) {
		for (int i=0;i<components.length;i++) {
			auto component2 = components[i];
			if (component.component == component2.component) {
				component2.storage.Remove(component.component);
				components[i] = components[components.length-1];
				components.length--;
				return true;
			}
		}
		return false;
	}

	public bool RemoveComponent(T)() {
		for (int i=0;i<components.length;i++) {
			auto component = components[i];
			if (component.Cast!T() !is null) {
				component.storage.Remove(component.component);
				components[i] = components[components.length-1];
				components.length--;  
				return true;
			}
		}
		return false;
	}
	
	public bool RemoveComponents(T)() {
		bool removed = false;
		for (int i=0;i<components.length;i++) {
			auto component = components[i];
			if (component.Cast!T() !is null) {
				component.storage.Remove(component.component);
				components[i] = components[components.length-1];
				components.length--;
				removed = true;
			}
		}
		return removed;
	}
}


