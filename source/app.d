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
import Engine.math;


Shader shader;
Camera camera; 
Texture ballTexture;


struct GravityMouse  {
	 mixin ComponentBase;

	 vec3 v = vec3(0,0,0);
	 static float force = 6.674*10e-6;

	 enum m1 = 100000;
	 enum m2 = 100;
	
			
	 void Update() {
		 auto mpos = vec3(Core.camera.MouseWorldPosition(),0);
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
				ship.AddComponent!(Sprite)(ballTexture);
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

void main(string[] args) {
	try {
		run();
	}
	catch (Exception e) {
		writeln(e.msg);
		scanf("\n");
	}
}

void run() {
	Core.Start();

	Font t = new Font("./public/arial.ttf\0", 32, Font.ASCII);
	ballTexture = new Texture("./public/sprite.png\0");
	ballTexture.SetFiltering(GL_LINEAR,GL_LINEAR);


	auto mmouse = new Entity();
	//mmouse.AddComponent!(Sprite)(ballTexture);
	mmouse.transform.scale = vec3(100, 100, 1);
	
			
	for (int i=0;i<10000;i++) {
		auto ship = new Entity();
		ship.AddComponent!(Sprite)(ballTexture);
		ship.AddComponent!(GravityMouse)();
		Core.AddEntity(ship);
		ship.transform.scale.x = 10;
		ship.transform.scale.y = 10;
		ship.transform.rotation = vec3(0,0,0);
		ship.name = to!string(i);
		ship.transform.position = vec3((i*2)%Core.width,((i/Core.width)*10)%Core.height,0);
		ship.transform.scale = vec3(4, 4, 1);
	}
	
	
	for (int i=0;i<10;i++) {
		auto e2 = new Entity();
		e2.transform.scale.x = 32;
		e2.transform.scale.y = 32;
		e2.AddComponent!GravityMouse();
		e2.transform.position = vec3(((i%100)*10)%Core.width,(i*25)%Core.height,0);
		e2.AddComponent!Label(t,to!string(i));
		Core.AddEntity(e2);	
	}

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
	auto fps = e3.AddComponent!Label(t,"FPS");
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
		auto sprite = mmouse.GetComponent!Sprite();
		auto dTexture = new DynamicTexture(sprite.material.texture);
		float t = 0;
		while (true) {
			if (sprite.color.r > 1)
				sprite.color.r = 0;

			alias Vector!(ubyte,4) color;

			dTexture.Update!(color)((pixels){
				for (int i=0;i<pixels.length;i++) {
					pixels[i].r = cast(ubyte)(i + t);
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

	Core.Run();
}
