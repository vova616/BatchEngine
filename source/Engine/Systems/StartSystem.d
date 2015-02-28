module Engine.Systems.StartSystem;

import Engine.System;
import Engine.Component;
import Engine.Entity;
import std.algorithm;

class StartSystem : System {
	alias Start = void delegate();
	Start[] comps;

	override void start() {
		comps = new Start[10];
		comps.length = 0;
	}


	override void process() {
		if (comps.length > 100)
			comps.sort!("a.funcptr > b.funcptr")();
		foreach(c; comps) {
			c();
		}
		comps.length = 0;
    } 

	@property override Timing timing() { 
		return Timing.Start;
	}

	override void onEntityEnter(Entity e) {
		foreach(c ; e.Components) {
			auto d = c.FindFunction!Start("Start");
			if (d !is null) {
				comps ~= d;
			}
        }
	}

	override void onEntityLeave(Entity e) {

	}
}