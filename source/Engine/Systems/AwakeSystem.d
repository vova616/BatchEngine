module Engine.Systems.AwakeSystem;


import Engine.System;
import Engine.Component;
import Engine.Entity;

import std.stdio;

class AwakeSystem : System {

	override void start() {

	}

	override void process() {

	}

	override void onEntityEnter(Entity e) {
		foreach(c ; e.Components) {
			c.RunFunction!(void delegate())("Awake");
        }
	}

	override void onEntityLeave(Entity e) {

	}
}