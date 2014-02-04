module Engine.System;


import Engine.Entity;

class System {
	@property abstract Timing timing();
	abstract void start();
	abstract void process();
	abstract void onEntityEnter(Entity e);
	abstract void onEntityLeave(Entity e);	
}

enum Timing {
	Awake = 0,
	Start = 1000,
	Update = 2000,
	Draw = 3000,
}

