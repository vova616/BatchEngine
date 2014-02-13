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
import Engine.Systems.SimpleSystem;
import Engine.Tree.BBTree;

Shader shader;
Camera camera; 
Texture ballTexture;

import std.parallelism;
import std.datetime;
import Engine.util;

class CollisionSystem : System {
	BBTree tree;

	@property override Timing timing() { 
		return Timing.Update;
	}

	
	override void start() {
		tree = new BBTree(null);
	}

	override void process() {
		tree.ReindexQuery(&checkCollision);
	} 

	ulong checkCollision(Indexable a,Indexable b, ulong collisionID) {
		auto ac = cast(Collider)a;
		auto bc = cast(Collider)b;
		if (ac.Collide(bc)) {
			ac.entity.SendMessage("OnCollision", bc);
			bc.entity.SendMessage("OnCollision", ac);
		}
		return 0;
	}

	override void onEntityEnter(Entity e) {
		foreach(c2 ; e.Components) {
			auto c = cast(Component)c2;
			auto collider = c.Cast!Collider();
			if (collider !is null) {
				tree.Insert(collider);
			}
		}
	}

	override void onEntityLeave(Entity e) {
		
	}
}


struct CollisionData {
public:
	vec2 point;
	vec2 normal;
	Entity a;
	Entity b;
}

class Collider : Indexable {
	mixin ComponentBase;
	enum Type {
		Box,
		Circle,
	}

	abstract @property Type type();
	rect BB() {
		return rect();
	}
	abstract bool Collide(Collider collider);
}

class BoxCollider : Collider {
	rect bb;
	
	void Awake() {
		bb = rect(transform.scale.x,transform.scale.y);
	}

	override @property Type type() {
		return Type.Box;
	}

	public override rect BB() {
		auto bc = bb;
		bc.add(transform.position.xy);
		return bc;
	}

	public override bool Collide(Collider collider) {
		if (collider.type() == Type.Box) {
			return BB.Intersects(BB(),collider.BB());
		} else {
			assert(0);
		}
		//return false;
	}
}

class CircleCollider : Collider {
	float radius;

	void Update() {
		if (transform.scale.x > transform.scale.y)
			radius = transform.scale.x/2f;
		else 
			radius = transform.scale.y/2f;
	}

	override @property Type type() {
		return Type.Circle;
	}

	public override rect BB() {
		auto bc = rect(vec2(-radius,-radius),vec2(radius,radius));
		bc.add(transform.position.xy);
		return bc;
	}

	public override bool Collide(Collider collider) {
		if (collider.type() == Type.Circle) {
			auto c = cast(CircleCollider)collider;
			auto dp = (c.transform.position.xy-transform.position.xy);
			auto d = ((c.radius+radius)*(c.radius+radius)) - (dp.x*dp.x + dp.y*dp.y);
			if (d >= 0) {
				return true;
			}
		} else {
			assert(0);
		}
		return false;
	}
}

class LifeController {
	mixin ComponentBase;

	Life life;

	void Awake() {
		life = entity.GetComponent!Life();
		writeln(life is null);
	}

	void Update() {
		if (Input.KeyPressDown(Key.MOUSE_BUTTON_1)) {
			auto mpos = vec3(Core.camera.MouseWorldPosition(),0);
			auto dir = (transform.position - mpos).xy;
			dir.normalize();
			life.Push(dir.xy, 100f);
		}	
	}
}

class Rigidbody  {
	mixin ComponentBase;
	vec2 velocity = vec2(0,0);

	void Update() {
		auto pos = transform.position;
		auto bounds = camera.bounds();
		auto min = bounds.min;
		auto max = bounds.max;
		if (pos.x < min.x) {
			velocity.x = -velocity.x;
			pos.x = min.x;
		} else if (pos.x > max.x) {
			velocity.x = -velocity.x;
			pos.x = max.x;
		}
		if (pos.y < min.y) {
			velocity.y = -velocity.y;
			pos.y = min.y;
		} else if (pos.y > max.y) {
			velocity.y = -velocity.y;
			pos.y = max.y;
		}
		transform.position = pos;
		transform.position += vec3(velocity,0) * Core.DeltaTime;
	}
}

class Life  {
	mixin ComponentBase;
	Energy energy;
	Rigidbody rigidbody;
	Collider collider;

	void Awake() {
		energy = entity.GetComponent!Energy();
		rigidbody = entity.GetComponent!Rigidbody();
		collider = entity.GetComponent!Collider();
	}

	void Push(vec2 dir, float force) {
		auto e = energy.energy*0.05f;
		energy.AddEnergy(-e);

		auto ball = new Entity();
		ball.AddComponent!(Sprite)(ballTexture);
		auto en = ball.AddComponent!(Energy)(e);
		ball.AddComponent!(CircleCollider)();
		auto rigid = ball.AddComponent!(Rigidbody)();
		ball.transform.position = transform.position + ((energy.Size()/2f)+en.Size()/2f) * vec3(-dir,0);
		ball.sprite.color = vec4(1,0,0,1);
		ball.AddComponent!(Life)();
		Core.AddEntity(ball);

		rigid.velocity = -dir * force;
		rigidbody.velocity += dir * (force/10f);
		
	}

	void OnCollision(Collider c) {
		auto e = c.entity.GetComponent!Energy();
		if (e) {
			if (energy.energy > e.energy) {
				if (e.energy > 0) {
					auto cc = cast(CircleCollider)c;
					auto cc2 = cast(CircleCollider)collider;

					//Calculate circle collision distance
					auto dp = (cc.transform.position.xy-transform.position.xy);
					auto d2 = dp.x*dp.x+dp.y*dp.y;
					auto d = sqrt(d2);
					//auto intersection = ((cc.radius+cc2.radius)*(cc.radius+cc2.radius)) - d2;
					//auto amount = sqrt(intersection) * Core.DeltaTime * 200f;

					auto r = cc.radius;
					auto R = cc2.radius;
					auto area = r*r*acos((d2+r*r-R*R)/(2*d*r))+R*R*acos((d2+R*R-r*r)/(2*d*R))-(0.5*sqrt((-d+r+R)*(d+r-R)*(d-r+R)*(d+r+R)));
					area = abs(area) / 10;
					if(area != area) {
						e.AddEnergy(-e.energy);
						energy.AddEnergy(e.energy);
					} else {
						if (area > e.energy) {
							area = e.energy;
						}
						e.AddEnergy(-area);
						energy.AddEnergy(area);
					}


					//move the target circle
					//c.transform.position += vec3(dp.normalized*amount,0);

					//exchange sizes
					//e.AddSize(-amount);
					//energy.AddSize(amount);
				}
			}
		}
	}
}

class Energy  {
	mixin ComponentBase;
	float energy;
	float sizeRatio = 1.5f;
	private float radius;
	private float size;

	this(float energy) {
		setEnergy(energy);
	}

	void Awake() {
		SetEnergy(energy);
	}

	void AddEnergy(float energy) {
		SetEnergy(this.energy + energy);
	}

	float Radius() {
		return Size() / 2;
	}

	private void setEnergy(float energy) {
		this.energy = energy;
		if (this.energy <= 0) {
			this.energy = 0;
			this.entity.Destory();
		}
		radius = sqrt(energy/PI);
		size = radius*2;
		if (size < 1) {
			entity.Destory();
		}
	}

	void SetEnergy(float energy) {
		setEnergy(energy);
		transform.scale = vec3(size,size,size);
	}

	
	float Size() {
		return size;
	}
}

struct InputHandle  {
	void Update() {
		if (Input.MouseScroll().y > 0)  {
			Core.camera.size += 3*Core.DeltaTime;
			Core.camera.UpdateResolution();
		}	
		if (Input.MouseScroll().y < 0) {
			Core.camera.size -= 3*Core.DeltaTime;
			Core.camera.UpdateResolution();
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
	ballTexture = new Texture("./public/sprite2.png\0");
	//ballTexture.SetFiltering(GL_LINEAR,GL_LINEAR);

	//Core.AddSystem(new GravitySystem());
	Core.AddSystem(new CollisionSystem());

	auto mmouse = new Entity();
	//mmouse.AddComponent!(Sprite)(ballTexture);
	mmouse.transform.scale = vec3(100, 100, 1);
	
	float entities = 20;
	float m = sqrt(entities/(Core.width*Core.height));
	for (int x=0;x<Core.width*m;x++) {
		for (int y=0;y<Core.height*m;y++) {
			auto ship = new Entity();
			ship.AddComponent!(Sprite)(ballTexture);
			ship.AddComponent!(CircleCollider)();
			ship.AddComponent!(Life)();
			ship.name = to!string(x) ~ " " ~ to!string(y);
			ship.transform.position = vec3(x/m,y/m,0);
			ship.AddComponent!(Energy)(20*30);
			Core.AddEntity(ship);
		}
	}

	auto cam = new Entity();
	camera = cam.AddComponent(new Camera());
	cam.AddComponent(new InputHandle());
	Core.AddEntity(cam);
	Core.camera = cam.GetComponent!Camera();

	cam.transform.position = vec3(Core.width/2,+Core.height/2,0);

	auto player = new Entity();
	player.AddComponent!(Sprite)(ballTexture);
	auto energy = player.AddComponent!(Energy)(60*30);
	player.AddComponent!(Life)();
	player.AddComponent!(LifeController)();
	player.AddComponent!(CircleCollider)();
	player.AddComponent!(Rigidbody)();
	player.name = "Player";

	player.transform.position = camera.transform.position;
	player.sprite.color = vec4(1,0,0,1);
	Core.AddEntity(player);
	
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
				fps.SetText("FPS: " ~ to!string(frames));
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

	Core.Run();
}
