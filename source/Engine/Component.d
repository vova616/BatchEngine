module Engine.Component;

import e = Engine.Entity;
import t = Engine.Transform;

abstract class Component
{
	package bool started;
	package e.Entity entity_;

	final @property public e.Entity entity() {
		return entity_;	
	};
	
	final @property public t.Transform transform() {
		return entity_.transform;
	};

	this()
	{
		
	}

	final package void onComponentAdd(e.Entity entity) {
		this.entity_ = entity;
		OnComponentAdd();
	};
	public void OnComponentAdd() {};
	public void Start() {};
	public void Update() {};
	public void Draw() {};
}

