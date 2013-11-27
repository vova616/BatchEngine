module Engine.Component;


import t = Engine.Transform;
import std.traits;
import e = Engine.Entity;

abstract class Component
{
	package bool started;
	package e.Entity _entity;

	final @property public e.Entity entity() {
		return _entity;	
	};

	final @property public t.Transform transform() {
		return _entity.transform;
	};

	this()
	{
		
	}

	final package void bind(e.Entity entity) {
		this._entity = entity;
	};

	public T Cast(T)() {
		return cast(T)this;
	}

	public void OnComponentAdd() {};
	public void Awake() {};
	public void Start() {};
	public void Update() {};
	public void LateUpdate() {};

	final @property package bool hasUpdate() {
		return ((&Update).ptr != (&Component.Update).ptr);
	};

	final @property package bool hasStart() {
		return ((&Start).ptr != (&Component.Start).ptr);
	};

	final @property package bool hasLateUpdate() {
		return ((&LateUpdate).ptr != (&Component.LateUpdate).ptr);
	};	
}


template ComponentBase()
{
	e.Entity _entity;
	
	final @property public e.Entity entity() {
		return _entity;	
	};

	final @property public t.Transform transform() {
		return entity.transform;
	};
}

public class ComponentImpl(T) : Component {
	static if (is(T == class)) {
		private byte[__traits(classInstanceSize, T)] raw;
	} 	
	T component;

	this()() {
		static if (is(T == class)) {
			component = cast(T)&raw;
			auto l = T.classinfo.init.length;
			raw[0..l] = T.classinfo.init[0..l];
			component.__ctor();
		}
	}

	this(Args...)(Args args) if (args.length > 0) {
		static if (is(T == class)) {
			component = cast(T)&raw;
			auto l = T.classinfo.init.length;
			raw[0..l] = T.classinfo.init[0..l];
			component.__ctor(args);	
		} else {	
			component = T(args);
		}
	}

	public override T Cast(T)() {
		static if (is(T == class)) {
			return cast(T)component;
		} else {
			return cast(T)&component;
		}
	}	
		
	static if(hasMember!(T, "Awake"))
	public override void Awake() {
		component.Awake();
	}

	static if(hasMember!(T, "Update"))
	public override void Update() {
		component.Update();
	}

	static if(hasMember!(T, "OnComponentAdd"))
	public override void OnComponentAdd() {
		component.OnComponentAdd();
	}

	final package void bind(e.Entity entity) {
		super.bind(entity);
		(cast(e.Entity)component._entity) = entity;
	}
}