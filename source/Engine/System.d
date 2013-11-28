module Engine.System;


import Engine.Entity;

class System {
	abstract void start();
	abstract void process();
	abstract void onEntityEnter(Entity e);
	abstract void onEntityLeave(Entity e);
}

