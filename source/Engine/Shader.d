module Engine.Shader;

import std.stdio;
import derelict.opengl3.gl;
import Engine.Batch;
import Engine.math;


class Shader {
    immutable
    GLuint Program;
	package
    static
    GLuint currentProgram = -1;
    Attribute[string] attributes;

    @property
    const(Attribute[string]) Attributes() {
		return attributes;
    }

	this(immutable string vertexShaderSource,immutable string fregmentShaderSource) {
		auto vertexShader = glCreateShader(GL_VERTEX_SHADER); 

		auto vertexSourcePtr = cast(const char*)vertexShaderSource.ptr;
        glShaderSource(vertexShader, 1, &vertexSourcePtr , null);
        glCompileShader(vertexShader);

        int result = 0;
        glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &result);
		if (result != GL_TRUE) {
            int InfoLogLength = 0;
            glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &InfoLogLength);
			if ( InfoLogLength > 0 ) {
                char[] message = new char[InfoLogLength];
				scope( exit )
                destroy(message); 
                glGetShaderInfoLog(vertexShader, InfoLogLength, null, cast( char*)&message[0]);
				throw new Exception(cast(string)message);
            }
        }

		auto fregmentShader = glCreateShader(GL_FRAGMENT_SHADER); 

		auto fregmentShaderPtr = cast(const char*)fregmentShaderSource.ptr;
        glShaderSource(fregmentShader, 1, &fregmentShaderPtr , null);
        glCompileShader(fregmentShader);

        result = 0;
        glGetShaderiv(fregmentShader, GL_COMPILE_STATUS, &result);
		if (result != GL_TRUE) {
            int InfoLogLength = 0;
            glGetShaderiv(fregmentShader, GL_INFO_LOG_LENGTH, &InfoLogLength);
			if ( InfoLogLength > 0 ) {
                char[] message = new char[InfoLogLength];
				scope( exit )
                destroy(message) ;
                glGetShaderInfoLog(fregmentShader, InfoLogLength, null, cast( char*)&message[0]);
				throw new Exception(cast(string)message);
            }
        }

		auto program = glCreateProgram();
        glAttachShader(program, vertexShader);
        glAttachShader(program, fregmentShader);
        glLinkProgram(program);

        result = 0;
        glGetProgramiv(program, GL_LINK_STATUS, &result);
		if (result != GL_TRUE) {
            int InfoLogLength = 0;
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &InfoLogLength);
			if ( InfoLogLength > 0 ) {
                char[] message = new char[InfoLogLength];
				scope( exit )
                destroy(message) ; 
                glGetProgramInfoLog(program, InfoLogLength, null, cast( char*)&message[0]);
				throw new Exception(cast(string)message);
            }
        }

        int attribs = 0;
        glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, &attribs);
        int maxAttribLen = 0;
        glGetProgramiv(program, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxAttribLen);


		for (
        int i = 0;i<attribs;i++) {
            int len = 0;
            int attribSize = 0;
            GLenum type = 0;
            char[] message = new char[maxAttribLen];
            glGetActiveAttrib(program,i,maxAttribLen,&len,&attribSize,&type,cast( char*)&message[0]);
            message = message[0..len];
			auto location = glGetAttribLocation(program, cast( char*)&message[0]);
            this.attributes[cast(string)(message)] = new Attribute(i,location,cast(string)(message),type);
        }

        attribs = 0;
        glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &attribs);
        maxAttribLen = 0;
        glGetProgramiv(program, GL_ACTIVE_UNIFORM_MAX_LENGTH, &maxAttribLen);

		for (
        int i = 0;i<attribs;i++) {
            int len = 0;
            int attribSize = 0;
            GLenum type = 0;
            char[] message = new char[maxAttribLen];
            glGetActiveUniform(program,i,maxAttribLen,&len,&attribSize,&type,cast( char*)&message[0]);
            message = message[0..len];
			auto location = glGetUniformLocation(program, cast( char*)&message[0]);
            this.attributes[cast(string)(message)] = new Attribute(i,location,cast(string)(message),type);
        }




        Program = program;
    }

    public
    void Use() {
		if (Program != currentProgram) {
            currentProgram = Program;
            glUseProgram(Program);
        }
    }

}

class Attribute {
	package this(int index, uint location, string name, GLenum type) {
        this.index = index;
        this.location = location;
        this.name = name;
        this.type = type;
    }

    immutable
    int index;
    immutable
    uint location;
    immutable
    string name;
    immutable       
    GLenum type;
        
    final
    void Set(vec4 v) const {
        glUniform4f(location, v.x,v.y,v.z,v.w);
    }

    final
    void Set(vec3 v) const {
        glUniform3f(location, v.x,v.y,v.z);
    }

    final
    void Set(vec2 v) const {
        glUniform2f(location, v.x,v.y);
    }

    final
    void Set(float v) const {
        glUniform1f(location, v);
    }

    final
    void Set(vec4d v) const {
        glUniform4d(location, v.x,v.y,v.z,v.w);
    }

    final
    void Set(vec3d v) const {
        glUniform3d(location, v.x,v.y,v.z);
    }

    final
    void Set(vec2d v) const {
        glUniform2d(location, v.x,v.y);
    }

    final
    void Set(double v) const {
        glUniform1d(location, v);
    }

    final
    void Set(vec4i v) const {
        glUniform4i(location, v.x,v.y,v.z,v.w);
    }

    final
    void Set(vec3i v) const {
        glUniform3i(location, v.x,v.y,v.z);
    }

    final
    void Set(vec2i v) const {
        glUniform2i(location, v.x,v.y);
    }

    final
    void Set(int v) const {
        glUniform1i(location, v);
    }

    final
    void Set(bool v) const {
        glUniform1i(location, cast(bool)v);
    }

    final
    void Set(ref mat4 m) const {
        glUniformMatrix4fv(location, 1, GL_TRUE, m.ptr);
    }

    final
    void Set(mat4 m) const {
        glUniformMatrix4fv(location, 1, GL_TRUE, m.ptr);
    }

}

