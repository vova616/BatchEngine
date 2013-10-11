module Engine.Core;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl;
public import gl3n.linalg;
import Engine.Entity;
import std.datetime;
import std.stdio;
import Engine.Input;
import Engine.Coroutine;
import Engine.Camera;
import Engine.Shader;
import Engine.Batch;
import std.parallelism;
import Engine.Options;
	
public class Core
{	
	public static GLFWwindow* window;
	package static Entity[] entities;
	package static Batch[] batches;
	public __gshared static auto width = 800;
	public __gshared static auto height = 600;
	static Camera camera;
	static Shader shader;

	public __gshared static double DeltaTime;

	public static void AddEntity(Entity entity) {
		entities ~= entity;
		entity.arrayIndex = entities.length-1;
		foreach (ref c; entity.components) {
			auto batch = cast(Batchable)c;
			if (batch !is null)
				AddBatch(entity, batch);
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

	public static void RemoveEntity(Entity entity) {
		if (entity.inScene) {
			auto index = entity.arrayIndex;
			auto replaceEntity = entities[entities.length-1];
			entities[index] = replaceEntity;
			replaceEntity.arrayIndex = index;
			entity.arrayIndex = -1;
			//entities[entities.length-1] = null; no idea how array resize works
			entities.length--;
		}
	}

	public static void Start()
	{
		entities = new Entity[100];
		entities.length = 0;
		DerelictGLFW3.load();
		DerelictGL3.load();
	

		if(!glfwInit()) 
			throw new Exception("glfwInit failure");



		glfwWindowHint(GLFW_VERSION_MAJOR, 2); // Use OpenGL Core v3.2
		glfwWindowHint(GLFW_VERSION_MINOR, 1);


		window = glfwCreateWindow(width,height,"SpaceSim",null,null);
		if (!window)
			throw new Exception("Failed to create window."); 
		
		

		glfwMakeContextCurrent(window);
		DerelictGL3.reload(); 

		glfwSwapInterval(0);		
		Input.Initialize();
		
		if (glMapBufferRange is null) {
			Options.useMapBufferRange = false;
		}

		glDisable(GL_CULL_FACE);
		glClearDepth(1);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
		glDepthFunc(GL_NEVER);
		glEnable(GL_BLEND);
		glDepthMask(true);
		initShaders();
		
		//glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
		//glLineWidth(5);
	}

	private static void initShaders() {
		const auto vertexSource = q"[
			#version 120
			// Input vertex data, different for all executions of this shader.
			attribute vec2 uv;
			attribute vec4 color;
			attribute vec3 vertex;
			attribute mat3 models;
			//uniform mat4 model;
			uniform mat4 projection;
			uniform mat4 view;
			varying vec2 UV;
			varying vec4 Color;
			//uniform sampler2D transforms;

			const float PI = 3.14159265358979323846264 / 180.0;

			void main(){
			vec3 rot = models[1]*PI;

			mat3 rotm = mat3(1,0,0,
			0,cos(rot.x),-sin(rot.x),
			0,sin(rot.x),cos(rot.x))
			*

			mat3(cos(rot.y),0,sin(rot.y),
			0,1,0,
			-sin(rot.y),0,cos(rot.y))
			*

			mat3(cos(rot.z),-sin(rot.z),0,
			sin(rot.z),cos(rot.z),0,
			0,0,1);

			vec3 pos = (rotm*(vertex*models[2]))+models[0];

			gl_Position =  projection * view * vec4(pos, 1.0);
			UV = uv;
			Color = color;
			}
			]";	


		const auto fragSource = q"[
			#version 120
			varying vec2 UV; 
			varying vec4 Color;
			uniform sampler2D texture;

			void main()
			{
			gl_FragColor = texture2D(texture, UV) * Color;
			}
			]";	

		shader = new Shader(vertexSource, fragSource);
		Core.shader = shader;
	}

	public static void Terminate()
	{
		glfwTerminate() ; 
	}

	public static void Run()
	{
		StopWatch sw;
		sw.start();
		while (!glfwWindowShouldClose(window)) 
		{ 		
			DeltaTime = cast(double)sw.peek().nsecs / 1000000000;	
			sw.reset();

			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); 

			StopWatch t1;
			t1.start();

			t1.stop();
			//writeln("START", cast(double)sw.peek().nsecs / 1000000000);

			t1.start();
			foreach ( e; entities) {
				foreach ( c; e.components) {
					c.Update();
				}
			}
			t1.stop();
			//writeln("Update ", cast(double)sw.peek().nsecs / 1000000);

			RunCoroutines();

			t1.start();
			foreach (ref b; batches) {
				b.Update();
				b.Draw();
			}
			t1.stop();
			//writeln("Draw ", cast(double)sw.peek().nsecs / 1000000000);
			//import core.memory;
			Input.Update();
			//GC.enable();
			glfwSwapBuffers(window);
			glfwPollEvents();
			//GC.disable();
		}
	}
}

