module main;

import std.stdio;
import derelict.glfw3.glfw3;
import Engine.all;
import derelict.opengl3.gl;
import std.conv;
import std.random;
import Engine.Material;
import Engine.UI.all;
import std.math;
import std.variant;

Shader shader;
Camera camera; 

class System {
	abstract void start();
	abstract void process();
}

struct Position {
	vec3 position;
	
	alias position this;
}

struct Position2 {
	vec3 position;

	alias position this;
}


class CEntity {
	Variant[] Components;
}

template CSystem(C...) {
	class CSystem {
		
		bool check(CEntity e) {
			Continue:
			foreach(i, c ;C) {
				foreach(c2 ;e.Components) {
					if (typeid(c) == c2.type()) {
						continue Continue;
					}
				}
				return false;
			}			
			return true;
		}

		abstract void start();
		abstract void process();
	}
}

class MovementSystem : CSystem!(Position*) {
	
	override void start() {
		
	}

	override void process() {

	}
}


class GravityMouse : Component {
	
	 vec3 v = vec3(0,0,0);
	 static float force = 1000;

	 override void Update() {
		 auto pos = vec3(Core.camera.MouseWorldPosition(),0);
		

		
		// 
		// writeln(Core.camera.transform.scale);

		 auto dir = (pos - transform.Position);
		 auto dis = (dir.x*dir.x)+(dir.y*dir.y);
		 dir.normalize();
		 if (dis > force/10) {
			 v += dir * (force / dis) * 6.674;
			 //v.z = 0.01;
		 } else {
			 v += dir * 10 * 6.674;
			 //v.z = 0.01;
		 }	
		 transform.Position += v  * cast(float)Core.DeltaTime;
		 auto sprite = entity.sprite;
		 auto v2 = v;
		 if (v2.x < 0) v2.x = -v2.x;
		 if (v2.y < 0) v2.y = -v2.y;

		 if (sprite !is null) {
			 sprite.color = vec4((v2.y+2*v2.x)/50, v2.x/50,v2.y/60,1);
		 } //else {
			// transform.Rotation.z = atan2(v.x, v.y) * 180f/PI;
		// transform.Scale.x = (v2.x+v2.y)/20 + 5;
		// transform.Scale.y = transform.Scale.x;
	 }
}

class InputHandle : Component {
	override void Update() {
		if (Input.KeyDown(Key.Q))  {
			Core.camera.size += 0.5*Core.DeltaTime;
			Core.camera.UpdateResolution();
		}	
		if (Input.KeyDown(Key.W)) {
			Core.camera.size -= 0.5*Core.DeltaTime;
			Core.camera.UpdateResolution();
		}
		if (Input.KeyDown(Key.A)) {
			Core.camera.transform.Rotation.y -= Core.DeltaTime;
		}
		if (Input.KeyDown(Key.S)) {
			Core.camera.transform.Rotation.y += Core.DeltaTime;
		}
		if (Input.KeyDown(Key.E)) {
			GravityMouse.force += GravityMouse.force*Core.DeltaTime*2;
		}	
		if (Input.KeyDown(Key.R)) {
			GravityMouse.force -= GravityMouse.force*Core.DeltaTime*2;
		}
	}
}


struct dirty(T) {
	bool dirty;
	T val;

	alias v this;	

	@property const(T) v() {
		return val;
	}

	void opOpAssign(R)(auto ref const R r) {
		static if (__traits(compiles, val.opAssign!R(r))) {
			dirty = true;
			val.opOpAssign!R(r);	
		}
	}

	void opAssign(R)(auto ref const R r) {
		static if (__traits(compiles, val.opAssign!R(r))) {
			val.opAssign!R(r);
		} else {
			val = r;
		}
		dirty = true;
	}
}

class A {
	dirty!(vec3) position;

}

void main(string[] args) {
	/*
	A a = new A();
	a.position = vec3(0,0,0);
	a.position.dirty = false;
	auto v = a.position.x;
	writeln(a.position.dirty);
	a.position.x = 10;
	writeln(a.position.dirty);
*/
	try {
		run();
	}
	catch (Exception e) {
		writeln(e.msg);
		scanf("\n");
	}
}


void run() {
	// Prints "Hello World" string in console
	{
		auto r = mat4.identity.rotatex(0).rotatey(0).rotatez(0);
		auto s = mat4.identity.scale(0.9, 0.9, 0.9);
		auto t =  mat4.identity.translation(400, 400, 0);
		auto m = t*r*s;
		auto mi = m;
		mi.invert();
		writeln("\nRotate ",r, "\nScale ", s, "\nTranslate", t, "\nMatrix " , m , "\nInvert ", mi);
	}
	Core.Start();

	
		
	auto ct = new CEntity();
	ct.Components.length++;
	ct.Components[0] = new Position(vec3(10,0,0));
	auto d = new MovementSystem();
	assert(d.check(ct));
	d.start();
	

	Font t = new Font("./public/arial.ttf\0", 32, Font.ASCII);
	auto shipTexture = new Texture("./public/sprite.png\0");
	shipTexture.SetFiltering(GL_LINEAR,GL_LINEAR);
	//for (int i=0;i<10000;i++) {
	auto e = new Entity();
	e.AddComponent(new Sprite(t.Atlas));
	//Core.AddEntity(e);
	e.transform.Scale.x = 500;
	e.transform.Scale.y = 500;
	e.transform.Position = vec3(200,400,0);
	
	e.transform.Scale = vec3(t.Atlas.width, t.Atlas.height, 1);
	//}
	
	//batch.transform.Scale = vec3(shipTexture.width, shipTexture.height, 1);
	
	auto mmouse = new Entity();
	//mmouse.AddComponent(new Sprite(shipTexture));
	//Core.AddEntity(mmouse);
	mmouse.transform.Scale = vec3(100, 100, 1);
	
			
	for (int i=0;i<10000;i++) {
		auto ship = new Entity();
		ship.AddComponent(new Sprite(shipTexture));
		ship.AddComponent(new GravityMouse());
		//ship.AddComponent(new GameOfLife());
		Core.AddEntity(ship);
		ship.transform.Scale.x = 500;
		ship.transform.Scale.y = 500;
		ship.transform.Rotation = vec3(0,0,0);
		ship.name = to!string(i);
		ship.transform.Position = vec3((i*2)%Core.width,((i/Core.width)*10)%Core.height,0);
		//ship.transform.Position += vec3(0,10000,0);
		//ship.transform.Position = vec3(uniform(0,Core.width),uniform(0,Core.height),0);
		ship.transform.Scale = vec3(4, 4, 1);
	}
	
	
	for (int i=0;i<10;i++) {
		auto e2 = new Entity();
		e2.transform.Scale.x = 32;
		e2.transform.Scale.y = 32;
		e2.AddComponent(new GravityMouse());
		e2.transform.Position = vec3(((i%100)*10)%Core.width,(i*25)%Core.height,0);
		e2.AddComponent(new Label(t,to!string(i)));
		Core.AddEntity(e2);	
	}

	auto e2 = new Entity();
	e2.transform.Scale.x = 32;
	e2.transform.Scale.y = 32;
	e2.AddComponent(new GravityMouse());
	e2.transform.Position = vec3(200,400,0);
	e2.AddComponent(new Label(t,"Hallo FCUKER"));
	//Core.AddEntity(e2);	


	auto cam = new Entity();
	camera = cam.AddComponent(new Camera());
	cam.AddComponent(new InputHandle());
	Core.AddEntity(cam);
	Core.camera = cam.GetComponent!Camera();

	cam.transform.Position = vec3(Core.width/2,+Core.height/2,0);
	

	

	auto e3 = new Entity();
	e3.transform.Scale.x = 32;
	e3.transform.Scale.y = 32;
	e3.transform.Position = vec3(100,Core.height-50,0);
	auto fps = new Label(t,"FPS");
	e3.AddComponent(fps);
	Core.AddEntity(e3);	

	StartCoroutine( {
		float time = 0;
		int frames = 0;
		while (true) {
			time += Core.DeltaTime;
			frames++;
			if (time >= 1) {
				fps.SetText("FPS: " ~ to!string(frames));
				writeln(to!string(frames));
				time -= 1;
				frames = 0;
				
			}
			auto camRect = Core.camera.rect;
			fps.entity.transform.Position = vec3(camRect.min.x + 10, camRect.max.y - 10,0);
			fps.entity.transform.Scale = vec3(1,1,1)* Core.camera.size * 34;
			auto pos = Input.MousePosition();
			pos.y = Core.height - pos.y;
			mmouse.transform.Position = vec3(pos,0);
		
			Coroutine.yield();
		}
	});
	/*
	StartCoroutine( {
		auto sprite = ship.GetComponent!Sprite();
		auto dTexture = new DynamicTexture(sprite.texture);
		float t = 0;
		while (true) {
			if (sprite.color.r > 1)
				sprite.color.r = 0;
			
			dTexture.Update!(Vector!(ubyte,4))((pixels){
				for (int i=0;i<pixels.length;i++) {
					pixels[i].r =  cast(ubyte)(i + t);
					pixels[i].g = cast(ubyte)(i + t);
					pixels[i].b = 0xff;
					pixels[i].a = 0xff;
				}
			});
			t += Core.DeltaTime*1000;
			//sprite.color.r += 0.1;
			Coroutine.yield();
		}
	});
	*/


	//new Texture("./test3.gif");

	Core.Run();
}
