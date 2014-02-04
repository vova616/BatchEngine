module Engine.Core;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl;
import Engine.math;
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
import Engine.System;
import Engine.Systems.UpdateSystem;
import Engine.Systems.AwakeSystem;
import Engine.Systems.StartSystem;
import Engine.Systems.BatchSystem;
import std.algorithm;

public
class Core {	
    public static GLFWwindow* window;
    package static Entity[] entities;
    
    package static System[] systems;
    public shared static auto width = 800;
    public shared static auto height = 600;
    static Camera camera;
    static Shader shader;

    public shared static double DeltaTime;

    public static size_t EntitiesCount() {
        return entities.length;
    }

    public static void AddEntity(Entity entity) {
        entities ~= entity;
        entity.arrayIndex = entities.length-1;
        entity.onActive();
        foreach ( s; systems) {
            s.onEntityEnter(entity);
        }
    }
    
    public static void AddSystem(System s) {
        systems ~= s;
        sort!"a.timing < b.timing"(systems);
        s.start();
        foreach ( e; entities) {
            s.onEntityEnter(e);
        }
    }

    public static bool RemoveSystem(System system) {
        foreach ( index,
                 s; systems) {
            if (system == s) {
                systems[index] = systems[systems.length-1];
                systems.length--;
                sort!"a.timing < b.timing"(systems);
                return true;
            }
        }
        return false;
    }   

    public static void RemoveEntity(Entity entity) {
        if (entity.inScene) {
            foreach ( s; systems) {
                s.onEntityLeave(entity);
            }
            auto index = entity.arrayIndex;
            auto replaceEntity = entities[entities.length-1];
            entities[index] = replaceEntity;
            replaceEntity.arrayIndex = index;
            entity.arrayIndex = -1;
            entities[entities.length-1] = null; //no idea how array resize works, but lets do it safe
            entities.length--;
        }
    }

    public static void Start() {
        entities = new Entity[100];
        entities.length = 0;

        systems ~= new AwakeSystem();
        systems ~= new StartSystem();
        systems ~= new UpdateSystem();
        systems ~= new BatchSystem();

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
        foreach ( s; systems) {
            s.start();
        }
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

    public static void Terminate() {
        glfwTerminate() ; 
    }

    public static void Run() {
        StopWatch sw;
        sw.start();
        while (!glfwWindowShouldClose(window)) { 		
            DeltaTime = cast(double)sw.peek().nsecs / 1000000000;	
            sw.reset();

            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); 

            StopWatch t1;
            t1.start();

            t1.stop();
            //writeln("START", cast(double)sw.peek().nsecs / 1000000000);

            t1.start();
            foreach ( s; systems) {
                s.process();
            }
            t1.stop();
            //writeln("Update ", cast(double)sw.peek().nsecs / 1000000);

            RunCoroutines();

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

