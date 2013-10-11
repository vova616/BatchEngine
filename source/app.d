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

class GravityMouse : Component {
	
	 vec3 v = vec3(0,0,0);
	 static float force = 1000;

	 override void Update() {
		 auto pos = vec3(Input.MousePosition(),0);
		 pos.y = Core.height - pos.y;

		
		// 
		// writeln(Core.camera.transform.scale);

		 auto dir = (pos - transform.Position);
		 auto dis = (dir.x*dir.x)+(dir.y*dir.y);
		 dir.normalize();
		 if (dis > force/10) {
			 v += dir * (force / dis) * 6.674;
			 v.z = 0.01;
		 } else {
			 v += dir * 10 * 6.674;
			 v.z = 0.01;
		 }
		 transform.Position += v  * cast(float)Core.DeltaTime;
		 auto sprite = entity.sprite;
		 auto v2 = v;
		 if (v2.x < 0) v2.x = -v2.x;
		 if (v2.y < 0) v2.y = -v2.y;

		 if (sprite !is null) {
			 sprite.color = vec4((v2.y+2*v2.x)/50, v2.x/50,v2.y/60,1);
		 } else {
			 transform.Rotation.z = atan2(v.x, v.y) * 180f/PI;
		 }
		// transform.Scale.x = (v2.x+v2.y)/20 + 5;
		// transform.Scale.y = transform.Scale.x;
	 }
}

class GameOfLife : Component {

	static bool[] map ;
	static bool stop = false;
	static int width;
	static int height;
	int x,y;
	bool* val;

	override void Start() {
		if (map is null) {
			width = Core.width / 10;
			height = Core.height / 10;
			map = new bool[width*height];
			StartCoroutine({
				int ticks = 0;
				while (true) {
					while (stop)
						Coroutine.yield();

					while (ticks >= 30) {
						ticks -= 30;
						for (int y=0;y<Core.height;y++) {
							for (int x=0;x<Core.width;x++) {
								
								int nibors = 0;

								auto occ = Get(x,y);

								if (Get(x+1,y)) nibors++;
								if (Get(x-1,y)) nibors++;
								if (Get(x,y+1)) nibors++;
								if (Get(x,y-1)) nibors++;
								if (Get(x+1,y+1)) nibors++;
								if (Get(x+1,y-1)) nibors++;
								if (Get(x-1,y+1)) nibors++;
								if (Get(x-1,y-1)) nibors++;

								if (occ) {
									if (nibors <= 1 || nibors >= 4) {
										Set(x,y, false);
									}
								} else {
									if (nibors == 3) {
										Set(x,y, true);
									}
								}
							}
						}
					}
					ticks++;
					Coroutine.yield();
				}
			});
		}

		auto p = transform.Position;
		x = cast(int)(p.x / 10);
		y = cast(int)(p.y / 10);
		if (x > 0 && x < width && y > 0 && y < height) {
			val = &map[y*width + x];
			*val = true;
		} else {
			entity.RemoveComponent!GameOfLife();
		}
	}

	void Set()(int x,int y, bool val) {
		map[y*width + x] = val; 
	}

	bool Get()(int x,int y) {
		if (x < 0 || x >= width || y < 0 || y >= height) {
			return false;
		}
		return map[y*width + x]; 
	}

	override void Update() {
		if (*val) {
			transform.Scale = vec3(10,10,10);
		} else {
			transform.Scale = vec3(0,0,0);
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
	// Prints "Hello World" string in console


	Core.Start();

	

	

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
	
			
	for (int i=0;i<50000;i++) {
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
		ship.transform.Scale = vec3(32, 32, 1);
	}
	
	
	for (int i=0;i<0;i++) {
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
			auto pos = Input.MousePosition();
			pos.y = Core.height - pos.y;
			mmouse.transform.Position = vec3(pos,0);

			if (Input.KeyPressDown(Key.S)) {
				e3.transform.Position.y += 10;
				fps.SetText(fps.text ~ "a");
			}
			if (Input.KeyPressDown(Key.A)) {
				e3.transform.Position.y -= 10;
				fps.SetText(fps.text[0..$-1]);
			}
			if (Input.KeyDown(Key.Q)) {
				cam.transform.Scale += cam.transform.Scale()*(Core.DeltaTime*0.1f);
			}	
			if (Input.KeyDown(Key.W)) {
				cam.transform.Scale -= cam.transform.Scale()*(Core.DeltaTime*0.1f);
			}
			if (Input.KeyDown(Key.E)) {
				GravityMouse.force += GravityMouse.force*Core.DeltaTime*2;
			}	
			if (Input.KeyDown(Key.R)) {
				GravityMouse.force -= GravityMouse.force*Core.DeltaTime*2;
			}
			
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
