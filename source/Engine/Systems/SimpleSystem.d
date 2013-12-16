module Engine.Systems.SimpleSystem;

import Engine.System;
import Engine.CStorage;
import Engine.Entity;

class SimpleSystem : System {
    Component[] components;

    override void start() {
        components = new Component[10];
        components.length = 0;    
    }

    override void process() {
        foreach(c ; components) {
            process(c);
        }
    } 

	abstract bool check(Component c);
	abstract void process(Component c);

    override void onEntityEnter(Entity e) {
		return;
        foreach(c2 ; e.Components) {
            auto c = cast(Component)c2;
            if (check(c))
                components ~= c;
        }
    }
	override void onEntityLeave(Entity e) {
		for(int i=0;i<components.length;) {
			/*
            if (components[i].entity == e)
			{
				if (onRemove(e)) {
					components[i] = components[components.length-1];
					components.length--;
					continue;
				}
			}
			i++;
			*/
        }
    }

	public bool onRemove(Entity e) {
		return true;
	}
}