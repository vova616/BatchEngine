module Engine.Component;

import Engine.Entity;
import t = Engine.Transform;
import std.traits;
	
abstract class Component
{
	package bool started;
	package Entity entity_;

	final @property public Entity entity() {
		return entity_;	
	};
	
	final @property public t.Transform transform() {
		return entity_.transform;
	};

	this()
	{
		
	}

	final package void onComponentAdd(Entity entity) {
		this.entity_ = entity;
		OnComponentAdd();
	};
	public void OnComponentAdd() {};
	public void Start() {};
	public void Update() {};
	public void Draw() {};
}


template ComponentBase()
{
	Entity entity_;

	final @property public Entity entity() {
		return entity_;	
	};

	final @property public t.Transform transform() {
		return entity_.transform;
	};
}

import std.stdio;



public class ComponentImpl(T) : Component {
	T component;

	this()() {
		static if (is(T == class)) {
			static if (__traits(compiles, mixin("component = new T();"))) {
				component = new T();
			} else {
				component = cast(T)newInstance (T.classinfo);
			}
		}
	}

	this(Args...)(Args args) if (args.length > 0) {
		static if (is(T == class)) {
			component = new T(args);
		} else {
			component = T(args);
		}
	}

	static if(hasMember!(T, "Update"))
	public override void Update() {
		component.Update();
	}

	package void bind(Entity entity) {
		this.entity_ = entity;
		component.entity_ = entity;
	}
}