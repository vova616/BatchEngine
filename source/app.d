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

struct position {
	vec3 position;
	
	alias position this;
}

struct position2 {
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

class MovementSystem : CSystem!(position*) {
	
	override void start() {
		
	}

	override void process() {

	}
}


class GravityMouse  {
	 mixin ComponentBase;

	 vec3 v = vec3(0,0,0);
	 static float force = 6.674*10e-6;

	 const m1 = 100000;
	 const m2 = 100;

	 override void Update() {
		 auto mpos = vec3(Core.camera.MouseWorldPosition(),0);

		
		// 
		// writeln(Core.camera.transform.scale);

		 auto dir = (mpos - transform.position);
		 auto dis = (dir.x*dir.x)+(dir.y*dir.y);
		 dir.normalize();
		 if (dis > 1000) {
			v += dir * ((m1/dis) * m2 * force);
		 } else {
			v += dir * ((m1/1000) * m2 * force);
		 }		

		 auto pos = transform.position;
		 auto bounds = camera.bounds();
		 auto min = bounds.min;
		 auto max = bounds.max;

		 if (pos.x < min.x) {
			 v.x = -v.x/8;
			 pos.x = min.x;
		 } else if (pos.x > max.x) {
			 v.x = -v.x/8;
			 pos.x = max.x;
		 }
		 if (pos.y < min.y) {
			 v.y = -v.y/8;
			 pos.y = min.y;
		 } else if (pos.y > max.y) {
			 v.y = -v.y/8;
			 pos.y = max.y;
		 }
		 transform.position = pos;

		 transform.position += v  * cast(float)Core.DeltaTime;
		 auto sprite = entity.sprite;
		 auto v2 = v;
		 if (v2.x < 0) v2.x = -v2.x;
		 if (v2.y < 0) v2.y = -v2.y;

		 if (sprite !is null) {
			 sprite.color = vec4((v2.y+2*v2.x)/50, v2.x/50,v2.y/60,1);
		 } //else {
			// transform.rotation.z = atan2(v.x, v.y) * 180f/PI;
		// transform.scale.x = (v2.x+v2.y)/20 + 5;
		// transform.scale.y = transform.scale.x;
	 }
}

class InputHandle : Component {
	override void Update() {
		if (Input.MouseScroll().y > 0)  {
			Core.camera.size += 3*Core.DeltaTime;
			Core.camera.UpdateResolution();
		}	
		if (Input.MouseScroll().y < 0) {
			Core.camera.size -= 3*Core.DeltaTime;
			Core.camera.UpdateResolution();
		}
		if (Input.KeyDown(Key.A)) {
			Core.camera.transform.rotation.y = Core.camera.transform.rotation.y - Core.DeltaTime;
		}
		if (Input.KeyDown(Key.S)) {
			Core.camera.transform.rotation.y = Core.camera.transform.rotation.y - Core.DeltaTime;
		}
		if (Input.KeyDown(Key.E)) {
			GravityMouse.force += GravityMouse.force*Core.DeltaTime*2;
		}	
		if (Input.KeyDown(Key.R)) {
			GravityMouse.force -= GravityMouse.force*Core.DeltaTime*2;
		}
		if (Input.KeyDown(Key.MOUSE_BUTTON_1)) {
		{
			auto mpos = vec3(Core.camera.MouseWorldPosition(),0);
			for (int i=0;i<20;i++) {
				auto ship = new Entity();
				ship.AddComponent(new Sprite(ballTexture));
				ship.AddComponent!GravityMouse();
				//ship.AddComponent(new GameOfLife());
				Core.AddEntity(ship);
				ship.transform.scale.x = 10;
				ship.transform.scale.y = 10;
				ship.transform.rotation = vec3(0,0,0);
				ship.transform.position = mpos + vec3(-5+i/2,-5+i/2,0) ;
				//ship.transform.position += vec3(0,10000,0);
				//ship.transform.position = vec3(uniform(0,Core.width),uniform(0,Core.height),0);
				ship.transform.scale = vec3(4, 4, 1);
			}		
		}
		}
	}
}


import Engine.math;

class A {

	dirty!(vec3) position;
}

struct B {
	this(int b) {

	}
}

void main(string[] args) {

	A a = new A();
	
	a.position = vec3(50,0,0);
	a.position.dirty = false;
	auto v = a.position.x;
	assert(a.position.dirty == false);
	a.position.dirty = false;
	a.position.normalize();
	assert(a.position.dirty == true);
	a.position.dirty = false;
	a.position.x = 10;
	assert(a.position.dirty == true);
	a.position.dirty = false;
	a.position.update(vec3(0,0,0));
	assert(a.position.dirty == true);
	a.position.dirty = false;
	a.position += a.position;
	assert(a.position.dirty == true);

	dirty!int b = 10;
	b++;
	assert(b.dirty == true);
	b.dirty = false;
	b += 3;
	assert(b.dirty == true);

	try {
		run();
	}
	catch (Exception e) {
		writeln(e.msg);
		scanf("\n");
	}
}

Texture ballTexture;

void run() {
	Core.Start();
	
	auto ct = new CEntity();
	ct.Components.length++;
	ct.Components[0] = new position(vec3(10,0,0));
	auto d = new MovementSystem();
	assert(d.check(ct));
	d.start();
	

	Font t = new Font("./public/arial.ttf\0", 32, Font.ASCII);
	ballTexture = new Texture("./public/sprite.png\0");
	ballTexture.SetFiltering(GL_LINEAR,GL_LINEAR);
	//for (int i=0;i<10000;i++) {
	auto e = new Entity();
	e.AddComponent(new Sprite(t.Atlas));
	//Core.AddEntity(e);
	e.transform.scale.x = 500;
	e.transform.scale.y = 500;
	e.transform.position = vec3(200,400,0);
	
	e.transform.scale = vec3(t.Atlas.width, t.Atlas.height, 1);
	//}
	
	//batch.transform.scale = vec3(ballTexture.width, ballTexture.height, 1);
	
	auto mmouse = new Entity();
	//mmouse.AddComponent(new Sprite(ballTexture));
	//Core.AddEntity(mmouse);
	mmouse.transform.scale = vec3(100, 100, 1);
	
			
	for (int i=0;i<10000;i++) {
		auto ship = new Entity();
		ship.AddComponent(new Sprite(ballTexture));
		ship.AddComponent!(GravityMouse)();
		//ship.AddComponent(new GameOfLife());
		Core.AddEntity(ship);
		ship.transform.scale.x = 10;
		ship.transform.scale.y = 10;
		ship.transform.rotation = vec3(0,0,0);
		ship.name = to!string(i);
		ship.transform.position = vec3((i*2)%Core.width,((i/Core.width)*10)%Core.height,0);
		//ship.transform.position += vec3(0,10000,0);
		//ship.transform.position = vec3(uniform(0,Core.width),uniform(0,Core.height),0);
		ship.transform.scale = vec3(4, 4, 1);
	}
	
	
	for (int i=0;i<10;i++) {
		auto e2 = new Entity();
		e2.transform.scale.x = 32;
		e2.transform.scale.y = 32;
		e2.AddComponent!GravityMouse();
		e2.transform.position = vec3(((i%100)*10)%Core.width,(i*25)%Core.height,0);
		e2.AddComponent(new Label(t,to!string(i)));
		Core.AddEntity(e2);	
	}

	auto e2 = new Entity();
	e2.transform.scale.x = 32;
	e2.transform.scale.y = 32;
	e2.AddComponent!GravityMouse();
	e2.transform.position = vec3(200,400,0);
	e2.AddComponent(new Label(t,"Hallo FCUKER"));
	//Core.AddEntity(e2);	


	auto cam = new Entity();
	camera = cam.AddComponent(new Camera());
	cam.AddComponent(new InputHandle());
	Core.AddEntity(cam);
	Core.camera = cam.GetComponent!Camera();

	cam.transform.position = vec3(Core.width/2,+Core.height/2,0);
	
	auto e3 = new Entity();
	e3.transform.scale.x = 32;
	e3.transform.scale.y = 32;
	e3.transform.position = vec3(100,Core.height-50,0);
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
				fps.SetText("FPS: " ~ to!string(frames) ~ " GameObjects:" ~ to!string(Core.EntitiesCount) );
				writeln(to!string(frames));
				time -= 1;
				frames = 0;
			}	
			auto camRect = Core.camera.bounds();
			fps.entity.transform.position = vec3((camRect.max.x+camRect.min.x) / 2, camRect.max.y - 50*Core.camera.size,0);
			fps.entity.transform.scale = vec3(1,1,1) * Core.camera.size * 34;
			mmouse.transform.position = vec3(Core.camera.MouseWorldPosition(),0);

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
