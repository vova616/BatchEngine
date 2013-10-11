module Engine.Coroutine;

import core.thread;
import std.datetime;
import Engine.Entity;

Coroutine[] Coroutines;

void StartCoroutine(void delegate() dg) {
	new Coroutine(null, dg);
}

void StartCoroutine(void function() fn) {
	new Coroutine(null, fn);
}

package void RunCoroutines() {
	for (int i=0;i<Coroutines.length;i++) {
		auto co = Coroutines[i];
		if (co.state == Fiber.State.TERM) {
			Coroutines[i] = Coroutines[Coroutines.length-1];
			Coroutines.length--;
			i--;
			continue;
		}		
		co.call();
	}
}

class Coroutine : Fiber
{
	Entity entity;

	package this(Entity entity, void delegate() dg) {
		this.entity = entity;
		super(dg);
		Coroutines ~= this;
	}

	package this(Entity entity, void function() fn) {
		this.entity = entity;
		super(fn);
		Coroutines ~= this;
	}

	public static void wait(float sec) {
		StopWatch sw;
		sw.start();
		auto msecs = sec*1000;
		while (sw.peek().msecs < msecs) {
			Fiber.yield();
		}
	}

	public static void yield() {
		Fiber.yield();	
	}
}

