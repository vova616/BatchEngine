module Engine.Entity;

import Engine.Component;
import t = Engine.Transform;
import Engine.Core;
import Engine.Coroutine;
import std.stdio;
import Engine.Sprite;
import Engine.util;
import Engine.CStorage;
import std.bitmanip;

class Entity
{
	package Component[] components;
	package t.Transform transform_;
	package ptrdiff_t arrayIndex;
	BitArray componentsBits;
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
		componentsBits.length = ComponentStorage.bitCounter+1;
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
	
	public void SendMessage(Args...)(string name, Args args) {
		foreach( c; components) {
			c.RunFunction(name, args);
		}
	}
	
	public auto AddComponent(T, Args...)(Args args)  {
		auto t = StorageImpl!(T).allocate(args);
		components ~= new Component(t);
		StorageImpl!(T).Bind(t,this);	
		setComponentBit(StorageImpl!(T)._bitIndex, true);
		return t;	
	}	
	
	public auto AddComponent()(Component component)  {
		components ~= component;
		component.storage.Bind(component.component,this);
		setComponentBit(component.storage.bitIndex, true);
		return component;
	}	

	public auto AddComponent(T)(T component) if (!is(T == Component))  {
		auto c = new Component(component);
		components ~= c;
		c.storage.Bind(c.component,this);
		setComponentBit(c.storage.bitIndex, true);
		return component;
	}

	package void setComponentBit(int bit, bool flag) {
		if (bit >= componentsBits.length) {
			componentsBits.length = ComponentStorage.bitCounter;
		}
		componentsBits[bit] = flag;
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
		components.length = 0;
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
		ComponentStorage storage = component.storage;
		auto found = false;
		auto left = 0;
		for (int i=0;i<components.length;i++) {
			auto c = components[i];
			if (c.storage == storage) {
				if (component.component == c.component) {
					components[i] = components[components.length-1];
					components.length--;
					storage.Remove(component.component);
					found = true;
				} else {
					left++;
				}
			}	
		}
		if (found && left == 0) {
			setComponentBit(storage.bitIndex, false);
		}		
		return found;
	}	

	public bool RemoveComponents(T)() {
		auto found = false;
		auto left = 0;
		for (int i=0;i<components.length;i++) {
			auto component = components[i];
			if (component.Cast!T() !is null) {
				if (found && component.storage == StorageImpl!(T).it) {
					left++;
					continue;
				}
				components[i] = components[components.length-1];
				components.length--;	
				component.storage.Remove(component.component);	
				found = true;
			}
		}	
		if (found && left == 0) {
			setComponentBit(StorageImpl!(T)._bitIndex, false);
		}			
		return found;
	}
}


