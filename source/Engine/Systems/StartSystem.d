module Engine.Systems.StartSystem;

import Engine.System;
import Engine.CStorage;
import Engine.Entity;

import Engine.Systems.SimpleSystem;

class StartSystem : SimpleSystem {

	override bool check(Component c) {
		//return c.hasStart;
		return false;
	}

	override void process() {
		super.process();
		components.length = 0;
    } 

	override void process(Component c) {
		//c.Start();
	}
}