module Engine.Systems.UpdateSystem;

import Engine.System;
import Engine.CStorage;
import Engine.Entity;

import Engine.Systems.SimpleSystem;

class UpdateSystem : SimpleSystem {
   
	override bool check(Component c) {
		//return c.hasUpdate;
		return false;
	}

	override void process(Component c) {
		//c.Update();
	}
}