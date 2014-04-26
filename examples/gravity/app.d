module main;

import std.stdio;
import Engine.all;
import std.conv;
import std.random;
import Engine.Material;
import Engine.UI.all;
import std.math;
import std.variant;
import Engine.math;
import Engine.CStorage;

Shader shader;
Camera camera; 
Texture ballTexture;

import std.parallelism;
import std.datetime;
import Engine.util;

class GravitySystem : System {
	//GravityMouse[] components;

	override void start() {
		//components = new GravityMouse[1000];
		//components.length = 0;    
	}

	@property override Timing timing() { 
		return Timing.Update;
	}
	
	override void process() {
		auto bounds = camera.bounds();
		auto mpos = vec3(camera.MouseWorldPosition(),0);
		auto delta = Core.DeltaTime;
		auto force = GravityMouse.force;
		auto components = ComponentStorage.components!(GravityMouse)();

		auto stgs = ComponentStorage.componentsDeep!(GravityMouse)();

		StopWatch timer;
		timer.start();
		foreach (s; stgs) {
			/*
			 void closure(ConstArray!GravityMouse arr) {
			 foreach(c;arr) {
			 c.Step(mpos,force,delta,bounds);
			 }
			 }	
			 parallelRange!(10)(&closure,s);
			 */
			foreach(c; parallel(s)) {
				c.Step(mpos,force,delta,bounds);
			}
		}
		timer.stop();
		if (timer.peek.msecs > 10) {
			//writeln("slowdown ", timer.peek.msecs);
		}
	} 	

	override void onEntityEnter(Entity e) {
		
	}
	override void onEntityLeave(Entity e) {

	}
}

class GravityMouse  {
	mixin ComponentBase;
	vec3 v = vec3(0,0,0);
	static shared float force = 6.674*10e-6;

	enum m1 = 100000;
	enum m2 = 100;

	void _Update() {
		auto bounds = camera.bounds();
		auto mpos = vec3(camera.MouseWorldPosition(),0);
		auto delta = Core.DeltaTime;
		Step(mpos,force,delta,bounds);
	}

	void Step(vec3 mpos, float mforce, float delta, recti bounds) {
		auto pos = transform.position;
		auto dir = (mpos - pos);
		auto dis = (dir.x*dir.x)+(dir.y*dir.y);
		dir.normalize();
		if (dis > 1000) {
			v += dir * ((m1/dis) * m2 * mforce);
		} else {
			v += dir * ((m1/1000) * m2 * mforce);
		}		

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
		transform.position = pos + v * delta;

		auto sprite = entity.sprite;
		auto v2 = v;
		v2.x = abs(v2.x);
		v2.y = abs(v2.y);
		if (sprite !is null) {
			sprite.color = vec4((v2.y+2*v2.x)/50, v2.x/50,v2.y/60,1);
		}
		/*
		v2 *= 0.005;
		if (sprite !is null) {
			sprite.color = vec4(abs(sin(v2.x)), abs(sin(v2.y)),abs(sin(v2.x-v2.y)),1);
		} 
		*/
		/*
		 else {
		 transform.rotation.z = atan2(v.x, v.y) * 180f/PI;
		 transform.scale.x = (v2.x+v2.y)/20 + 5;
		 transform.scale.y = transform.scale.x;
		} 
		*/
	}
}

class GravityMouse2 : GravityMouse {
	public override void Step(vec3 mpos, float mforce, float delta, recti bounds) { 
		super.Step(mpos,mforce,delta,bounds);
		entity.sprite.color = vec4(1,1,1,1);
	}
}

struct InputHandle  {
	mixin ComponentBase;

	
	void Start() {
		writeln("InputHandler started");
	}

	void Update() {
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
					ship.AddComponent!GravityMouse2();
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


class HTest {
	int b;
}

class Test : HTest {
	mixin ComponentBase;
	
	public void Hello() {
		writeln("Hello");
	}
	
	public int Hello(int b) {
		writeln("Hello int ",b);
		this.b = b;
		return 0;
	}
}

struct TestA {
	int a;
	
	public void Foo() {
		writeln("Foo");
	}
}


bool tests() {
	
	void testComponent(Tp, Args...)(Args args) {
		alias T = baseType!Tp;
		Entity e = new Entity(false);   
		auto hTest = e.AddComponent!T(args);
		assert(e.GetComponent!T() == hTest);
		assert(e.RemoveComponent!T());
		assert(e.GetComponent!T() is null);
		e.AddComponent(new Component(hTest));
		assert(e.GetComponent!T() == hTest);
		assert(e.RemoveComponents!T());
		assert(e.GetComponent!T() is null); 
		e.Destory();
	}   

	testComponent!HTest();
	testComponent!TestA();
	testComponent!Test();  
	testComponent!GravityMouse(); 
	testComponent!GravityMouse2(); 
	testComponent!(HTest*)();
	testComponent!(TestA*)();
	testComponent!(Test*)();  
	testComponent!(GravityMouse*)(); 
	testComponent!(GravityMouse2*)();
	
	return true;
}

void main(string[] args) { 
	try {
		assert(tests());  
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
	//ballTexture.SetFiltering(GL_LINEAR,GL_LINEAR);

	Core.AddSystem(new GravitySystem());

	auto mmouse = new Entity();
	//mmouse.AddComponent!(Sprite)(ballTexture);
	mmouse.transform.scale = vec3(100, 100, 1);

	auto gravityBall = new Entity();
	gravityBall.AddComponent!(Sprite)(ballTexture);
	gravityBall.AddComponent!(GravityMouse)();
	gravityBall.transform.scale = vec3(4, 4, 1);
	

	float entities = 100000/3;
	float m = sqrt(entities/(Core.width*Core.height));
	for (int x=0;x<Core.width*m;x++) {
		for (int y=0;y<Core.height*m;y++) {
			auto gball = gravityBall.Clone();
			gball.name = to!string(x);
			gball.transform.position = vec3(x/m,y/m,0);
			Core.AddEntity(gball);
		}
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
	camera = cam.AddComponent!Camera();
	cam.AddComponent!InputHandle();
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
				fps.SetText("FPS: " ~ to!string(frames) ~ " Entities:" ~ to!string(Core.EntitiesCount) );
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
