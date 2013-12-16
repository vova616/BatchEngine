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
		foreach(c2 ; e.Components) {
			auto c = cast(Component)c2;
			c.RunFunction!(void delegate())("Awake");
        }
	}

	override void onEntityLeave(Entity e) {

	}
}