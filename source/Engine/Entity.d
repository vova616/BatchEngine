module Engine.Entity;

import Engine.Component;
import t = Engine.Transform;
import Engine.Core;
import Engine.Coroutine;
import std.stdio;
import Engine.Sprite;

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

package const static Component dummyComponent;

class Entity
{
	package Component[] components;
	package t.Transform transform_;
	package size_t arrayIndex;
	bool active;
	Sprite sprite;
	string name;

	
	@property package bool inScene() {
		return arrayIndex >= 0;
	};

	this()
	{
		components = new Component[5];
		components.length = 0;
		AddComponent(new t.Transform());
		active = true;
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
			
		//if ((&t.Start).funcptr != (&dummyComponent.Start).funcptr ) {
			
		//}
		
		(cast(Component)t).onComponentAdd(this);
		return t;
	}

	public T* AddComponent(T, Args...)(Args args) {
		auto t = new ComponentImpl!(T)(args);
		components ~= t;
		t.bind(this);
		t.OnComponentAdd();
		return &t.component;
	}
	
	public T GetComponent(T)() {
		foreach(ref c; components) {
			T t = cast(T)c;
			if (t !is null) {
				return t;
			}
		}
		return null;
	}

	public T GetComponent(T)(T component)  {
		foreach(ref c; components) {
			T t = cast(T)c;
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
			newC.started = false;
			t.AddComponent(newC);
		}
		return t;
	}

	public void Destory()
	{
		active = false;
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
	

