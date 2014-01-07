module Engine.Systems.BatchSystem;

import Engine.System;
import Engine.CStorage;
import Engine.Entity;
import Engine.Batch;


class BatchSystem : System {

	package static Batch[] batches;

	override void start() {

	}

	override void onEntityEnter(Entity e) {
		foreach(c ; e.Components) {
			auto b = c.Cast!(Batchable)();
			if (b !is null) {
				AddBatch(e,b);
			}
        }
	}

	override void onEntityLeave(Entity e) {
		foreach(c ; e.Components) {
			auto b = c.Cast!(BatchData)();
			if (b !is null) {
				b.batch.Remove(e, b.batchable);
			}
        }
	}

	public static void AddBatch(Entity entity, Batchable batch) {
		auto mat = batch.material;
		foreach(ref b; batches) {
			if (b.material == mat) {
				b.Add(entity,batch);
				return;
			}
		}	
		auto b = new Batch(4, mat);
		batches ~= b;
		b.Add(entity, batch);
	}

	public override void process() {
		foreach (ref b; batches) {
			b.Update();
			b.Draw();
		}
	}	
}