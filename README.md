2D Game Engine written in D, I'm just uploading it so I will have access from everywhere.
<br/>
I will update both this and GarageEngine when I will decide on the design.
<br/>
I cannot promise backwards compatibility at this point and things will change, but the goals and ideas will stay the same.

### Video
https://www.youtube.com/watch?v=uxigpoS9BZI

### Goals

- Learn D. :D
- Keep it simple.
- Focus on 2D but keep the system 3D friendly (positions,rotations,scales are all 3d).
- Simple but flexible Entity-Component-System, with option to highly customize Components and the design, the engine will come with default systems which can be removed/customized however you want.
- Very high performance rendering with fallbacks to different gl versions.
- Very high performance in general.
- Some kind of collision/physics system, the collision system will probably be default and physics engine will come in different package as external system.
- Sprite sheets/texture atlas, full and easy control.
- Basic GUI.
- Coroutines and Behavior Trees for the AI.
- Cross-Platform as much as possible (I'm testing it everytime with dmd/ldc on mac/windows both 32/64).
- Maybe somekind of transform parent-child hierarchy.
- Similar to Unity3D but with much more control.

### Features so far

- Rendering and updating 100k Entities 60fps (ldc).
- Font rendering.
- Batching.
- ECS. (WIP)
- Coroutines.
- Transform.
- Sprite.

### Systems

Basicly you can use both Systems and Components for your game functionality, systems are just processors for anything you want. 

For now there are few systems:
- AwakeSystem - calling "void Awake()" only once when added entity to game.
- StartSystem - callind "void Start()" only once during game loop.
- UpdateSystem - callind "void Update()" each game loop.
- BatchSystem - the batching system (currently is not written as a system).
There will be more systems but thats it for now.

You can create your own systems just look on the ones above.

### Components

Component can be struct/class but you must follow the guideline. <br/>
Here is the same component written in 3 different ways.

	class Gravity : Component {
		override void Update() {
			transform.position += vec3(0,-9.8f,0) * Core.DeltaTime;
		}
	}

	class Gravity {
		mixin ComponentBase;
		void Update() {
			transform.position += vec3(0,-9.8f,0) * Core.DeltaTime;
		}
	}

	struct Gravity {
		mixin ComponentBase;
		void Update() {
			transform.position += vec3(0,-9.8f,0) * Core.DeltaTime;
		}
	}
	
	
	...
	auto entity = new Entity();
	entity.AddComponent!(Gravity)();
	//or
	entity.AddComponent(new Gravity());
	Core.AddEntity(entity);
	
### Dependencies
-	gl3n
-	derelict-fi
-	derelict-gl3
-	derelict-glfw3
-	derelict-ft
