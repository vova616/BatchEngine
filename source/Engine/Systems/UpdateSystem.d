module Engine.Systems.UpdateSystem;

import Engine.System;
import Engine.Component;
import Engine.Entity;

import Engine.Systems.SimpleSystem;

class UpdateSystem : SimpleSystem {
   
	override bool check(Component c) {
		version(LDC) {
			return true;
		} else {
			return c.hasUpdate;
		}
	}

	override void process(Component c) {
		c.Update();
	}
}