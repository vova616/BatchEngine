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
import Engine.Systems.SimpleSystem;
import Engine.Tree.BBTree;

Shader shader;
Camera camera; 
Texture ballTexture;

import std.parallelism;

class CollisionSystem : System {
	BBTree tree = new BBTree(null);

    override void start() {
          
    }

    override void process() {
		
        tree.ReindexQuery(&checkCollision);
    } 

	ulong checkCollision(Indexable a,Indexable b, ulong collisionID) {
		auto ac = cast(Collider)a;
		auto bc = cast(Collider)b;
		writeln(ac.entity.name, " collides ", bc.entity.name);
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

class Collider : Component, Indexable {
	enum Type {
		Box,
		Sphere,
	}

	abstract @property Type type();
	rect BB() {
		return rect();
	}
	abstract bool Collide(Collider collider);
}

class BoxCollider : Collider {
	rect bb;
	
	override void Awake() {
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
		}
		return false;
	}
}


class LifeController : Component {
	Life life;

	override void Awake() {
		life = entity.GetComponent!Life();
		writeln(life is null);
	}

	override void Update() {
		if (Input.KeyPressDown(Key.MOUSE_BUTTON_1)) {
			auto mpos = vec3(Core.camera.MouseWorldPosition(),0);
			auto dir = (transform.position - mpos).xy;
			dir.normalize();
			life.Push(dir.xy, 10f);
		}	
	}
}

class Life : Component {
	Energy energy;

	vec2 velocity = vec2(0,0);


	override void Awake() {
		energy = entity.GetComponent!Energy();
	}

	void Push(vec2 dir, float force) {
		velocity += dir * force;
	}

	override void Update() {
		transform.position += vec3(velocity,0) * Core.DeltaTime;
	}
}

class Energy : Component {
	float energy;
	float sizeRatio = 1;

	this(float energy) {
		this.energy = energy;
	}

	override void Awake() {
		SetEnergy(energy);
	}

	void SetEnergy(float energy) {
		this.energy = energy;
		auto size = Size();
		transform.scale = vec3(size,size,size);
	}

	void SetSizeRatio(float sizeRatio) {
		this.sizeRatio = sizeRatio;
		auto size = Size();
		transform.scale = vec3(size,size,size);
	}
		
	float Size() {
		return energy * sizeRatio;
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

	//Core.AddSystem(new GravitySystem());
	Core.AddSystem(new CollisionSystem());

	auto mmouse = new Entity();
	//mmouse.AddComponent!(Sprite)(ballTexture);
	mmouse.transform.scale = vec3(100, 100, 1);
					
	float entities = 10;
	float m = sqrt(entities/(Core.width*Core.height));
	for (int x=0;x<Core.width*m;x++) {
		for (int y=0;y<Core.height*m;y++) {
			auto ship = new Entity();
			ship.AddComponent!(Sprite)(ballTexture);
			ship.AddComponent!(BoxCollider)();
			ship.name = to!string(x) ~ " " ~ to!string(y);
			ship.transform.position = vec3(x/m,y/m,0);
			ship.transform.scale = vec3(50, 50, 1);
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
	auto energy = player.AddComponent!(Energy)(35);
	player.AddComponent!(Life)();
	player.AddComponent!(LifeController)();
	player.AddComponent!(BoxCollider)();
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
