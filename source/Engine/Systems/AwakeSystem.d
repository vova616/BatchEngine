module Engine.Systems.AwakeSystem;


import Engine.System;
import Engine.CStorage;
import Engine.Entity;

import std.stdio;

class AwakeSystem : System {

	override void start() {

	}

	override void process() {

	}

	override void onEntityEnter(Entity e) {
		void delegate() awake;
		foreach(c2 ; e.Components) {
			awake.funcptr = null;
			auto c = cast(Component)c2;
			c.FindFunction(awake, "Awake");
			if (awake.funcptr !is null) {
				awake.ptr = c.component;
				awake();
			}
        }
	}

	override void onEntityLeave(Entity e) {

	}
}