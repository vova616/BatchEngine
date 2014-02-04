module Engine.Systems.SimpleSystem;

import Engine.System;
import Engine.Component;
import Engine.Entity;

class SimpleSystem : System {

    override void start() {
           
    }

    override void process() {
 
    } 


	abstract bool check(Component c);
	abstract void process(Component c);

    override void onEntityEnter(Entity e) {
	
    }
	override void onEntityLeave(Entity e) {
		
    }

	public bool onRemove(Entity e) {
		return true;
	}
}