module Engine.Systems.UpdateSystem;

import Engine.System;
import Engine.CStorage;
import Engine.Entity;

class UpdateSystem : System {
   
	override void start() {
		
	}
	
	override void process() {
		void delegate() update;
		foreach(cs ; ComponentStorage.getAll()) {
			update.funcptr = null;
			cs.FindFunction(update, "Update");
			if (update.funcptr !is null) {
				foreach (c; cs.Components()) {
					update.ptr = c;
					update();
				}
			}
		}
	}
	
	override void onEntityEnter(Entity e) {

	}
	
	override void onEntityLeave(Entity e) {
		
	}
}