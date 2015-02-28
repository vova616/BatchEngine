module main;

import std.stdio;
import std.conv;
import std.random;
import Engine.Material;
import Engine.UI.all;
import std.math;
import std.variant;
import Engine.math;
import Engine.all;
import Engine.CStorage;
import dbox;

Shader shader;
Camera camera; 
Texture ballTexture;

import std.parallelism;
import std.datetime;
import Engine.util;

class Physics : System {

	public static b2World* world;

	override void start() {
		// Define the gravity vector.
		b2Vec2 gravity = b2Vec2(0.0f, -20.0f);

		// Construct a world object, which will hold and simulate the rigid bodies.
		Physics.world = new b2World(gravity);

		
		b2BodyDef groundBodyDef;
		groundBodyDef.position.Set(0.0f, -10.0f);
		
		// Call the body factory which allocates memory for the ground body
		// from a pool and creates the ground box shape (also from a pool).
		// The body is also added to the world.
		b2Body* groundBody = world.CreateBody(&groundBodyDef);
		
		// Define the ground box shape.
		b2PolygonShape groundBox = new b2PolygonShape;
		
		// The extents are the half-widths of the box.
		groundBox.SetAsBox(10000.0f, 10.0f);
		
		// Add the ground fixture to the ground body.
		groundBody.CreateFixture(groundBox, 0.0f);
	}

	@property override Timing timing() { 
		return cast(Timing)(Timing.Update+1);
	}
	
	override void process() {
		auto bounds = camera.bounds();
		auto mpos = vec3(camera.MouseWorldPosition(),0);
		auto delta = Core.DeltaTime;
		auto components = ComponentStorage.components!(Rigidbody)();

		StopWatch timer;
		timer.start();

		float32 timeStep = 1.0f / 60.0f;
		int32 velocityIterations = 6;
		int32 positionIterations = 2;
		
		world.Step(timeStep, velocityIterations, positionIterations);

		foreach (c; components) {
			auto pos = c.Body.GetPosition();
			c.transform.position = vec3(pos.x, pos.y, 0);
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

class Rigidbody  {
	mixin ComponentBase;

	b2BodyDef bodyDef;
	b2Body* Body;

	void Awake() {
		// Define the ground body.
		bodyDef.type = b2_dynamicBody;
		bodyDef.position.Set(this.transform.position.x, this.transform.position.y);
		
		// Call the body factory which allocates memory for the ground body
		// from a pool and creates the ground box shape (also from a pool).
		// The body is also added to the world.
		Body = Physics.world.CreateBody(&bodyDef);

		b2CircleShape shape = new b2CircleShape();
		shape.m_radius = (this.transform.scale.x + this.transform.scale.y) / 4f;
		
		// Define the dynamic body fixture.
		b2FixtureDef fixtureDef;
		fixtureDef.shape = shape;
		
		// Set the box density to be non-zero, so it will be dynamic.
		fixtureDef.density = 1.0f;
		
		// Override the default friction.
		fixtureDef.friction = 0.3f;

		fixtureDef.restitution = 0.5f;
		
		// Add the shape to the body.
		Body.CreateFixture(&fixtureDef);	
		
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
		if (Input.KeyDown(Key.MOUSE_BUTTON_1)) {
			{
				auto mpos = vec3(Core.camera.MouseWorldPosition(),0);
				for (int i=0;i<5;i++) {
					auto ship = new Entity();
					ship.AddComponent!(Sprite)(ballTexture);
					ship.AddComponent(new Rigidbody());
					ship.transform.rotation = vec3(0,0,0);
					ship.transform.position = mpos + vec3(-5+i/2,-5+i/2,0) ;
					ship.transform.scale = vec3(10, 10, 1);
					Core.AddEntity(ship);
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
		assert(e.RemoveComponents!T());
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
	testComponent!(HTest*)();
	testComponent!(TestA*)();
	testComponent!(Test*)();  

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

	Core.AddSystem(new Physics());

	auto mmouse = new Entity();
	//mmouse.AddComponent!(Sprite)(ballTexture);
	mmouse.transform.scale = vec3(100, 100, 1);

	auto gravityBall = new Entity();
	gravityBall.AddComponent!(Sprite)(ballTexture);
	gravityBall.AddComponent!(Rigidbody)();
	gravityBall.transform.scale = vec3(15, 15, 1);
	

	float entities = 1000;
	float m = sqrt(entities/(Core.width*Core.height));
	for (int x=0;x<Core.width*m;x++) {
		for (int y=0;y<Core.height*m;y++) {
			auto gball = gravityBall.Clone();
			gball.name = to!string(x);
			gball.transform.position = vec3(x/m + cast(float)(y&20),y/m,0);
			Core.AddEntity(gball);
		}
	}
	
	

	for (int i=0;i<10;i++) {
		auto e2 = new Entity();
		e2.transform.scale.x = 32;
		e2.transform.scale.y = 32;
		e2.AddComponent!Rigidbody();
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
