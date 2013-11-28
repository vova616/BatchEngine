module Engine.Systems.AwakeSystem;


import Engine.System;
import Engine.Component;
import Engine.Entity;

class AwakeSystem : System {

	override void start() {

	}

	override void process() {

	}

	override void onEntityEnter(Entity e) {
		foreach(c2 ; e.Components) {
            auto c = cast(Component)c2;
            c.Awake();
        }
	}

	override void onEntityLeave(Entity e) {

	}
}