module Engine.Systems.StartSystem;

import Engine.System;
import Engine.CStorage;
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
		comps.sort!("a.funcptr > b.funcptr")();
		foreach(c; comps) {
			c();
		}
		comps.length = 0;
    } 

	override void onEntityEnter(Entity e) {
		foreach(c2 ; e.Components) {
			auto c = cast(Component)c2;
			auto d = c.FindFunction!Start("Start");
			if (d !is null) {
				comps ~= d;
			}
        }
	}

	override void onEntityLeave(Entity e) {

	}
}