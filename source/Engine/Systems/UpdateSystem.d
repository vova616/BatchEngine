module Engine.Systems.UpdateSystem;

import Engine.System;
import Engine.CStorage;
import Engine.Entity;

class UpdateSystem : System {
   
	override void start() {
		
	}
	
	override void process() {
		foreach(cs ; ComponentStorage.all()) {
			cs.RunFunction!(void delegate())("Update");
		}
	}
	
	override void onEntityEnter(Entity e) {

	}
	
	override void onEntityLeave(Entity e) {
		
	}
}