module Engine.Buffer;

import derelict.opengl3.gl;
import Engine.math;
import std.stdio;
import Engine.Options;

class Buffer {
	GLenum type;
	GLenum memtype;
	GLenum buffer;

	int size;

	alias buffer this;

	this(T)(T[] arr, GLenum type, GLenum memtype) {
		glGenBuffers(1, &buffer);
		glBindBuffer(type, buffer);
		glBufferData(type, T.sizeof * arr.length, &arr[0], memtype);

		this.type = type;
		this.memtype = memtype;
		this.size = T.sizeof * arr.length;
	}

	this()(int size, GLenum type, GLenum memtype) {
		glGenBuffers(1, &buffer);
		glBindBuffer(type, buffer);	
		glBufferData(type, size, null, memtype);
	
		this.type = type;
		this.memtype = memtype;
		this.size = size;
	}

	this()(long size, GLenum type, GLenum memtype) {
		this(cast(int)size, type, memtype);
	}

	final
	void Resize(long size) {
		Resize(cast(int)size);
	}

	final
	void Resize(int size) {
		this.size = size;
		glBindBuffer(type, buffer);	
		glBufferData(type, size, null, memtype);
	}

	final
	void Bind()() {
		glBindBuffer(type, buffer);
	}

	final
	void Unbind()() {
		glBindBuffer(type, 0);
	}

	void Update(T)(T[] arr, int offset = 0) {
		if (T.sizeof * arr
		.length + offset * T.sizeof > size
		) {
			throw new Exception("array type is too big for this buffer");
		}

		Bind();
		glBufferSubData(type, offset * T.sizeof, T.sizeof * arr.length, &arr[0]);
	}

	void Update(T)(void delegate(T[] arr) update) {
		auto arr = Map!T();
		scope( exit )
		Unmap();
		update(arr);
	}

	T[] Map(T)(size_t offset, size_t len) {
		Bind();
		// map the buffer object into client's memory
        // Note that glMapBufferARB() causes sync issue.
        // If GPU is working with this buffer, glMapBufferARB() will wait(stall)
        // for GPU to finish its job. To avoid waiting (stall), you can call
        // first glBufferDataARB() with NULL pointer before glMapBufferARB().
        // If you do that, the previous data in PBO will be discarded and
        // glMapBufferARB() returns a new allocated pointer immediately
        // even if GPU is still working with the previous data.
		//glBufferData(type, size, null, memtype);
		void* arrPTR;
		if (Options.useMapBufferRange) {
			arrPTR = glMapBufferRange(type,offset,len,GL_MAP_UNSYNCHRONIZED_BIT | GL_MAP_WRITE_BIT );
		} else {	
			arrPTR = glMapBuffer(type,GL_WRITE_ONLY);
		}
		if (arrPTR !is null) {
			return (cast(T*)arrPTR)[0..size/T.sizeof];
		} else {
			throw new Exception("cannot map buffer." );
		}
	}

	T[] Map(T)() {
		Bind();
		// map the buffer object into client's memory
        // Note that glMapBufferARB() causes sync issue.
        // If GPU is working with this buffer, glMapBufferARB() will wait(stall)
        // for GPU to finish its job. To avoid waiting (stall), you can call
        // first glBufferDataARB() with NULL pointer before glMapBufferARB().
        // If you do that, the previous data in PBO will be discarded and
        // glMapBufferARB() returns a new allocated pointer immediately
        // even if GPU is still working with the previous data.
		//glBufferData(type, size, null, memtype);
		void* arrPTR;
		if (Options.useMapBufferRange) {
			arrPTR = glMapBufferRange(type,0,size,GL_MAP_UNSYNCHRONIZED_BIT | GL_MAP_WRITE_BIT );
		} else {
			arrPTR = glMapBuffer(type,GL_WRITE_ONLY);
		}
		if (arrPTR !is null) {
			return (cast(T*)arrPTR)[0..size/T.sizeof];
		} else {
			throw new Exception("cannot map buffer." );
		}
	}

	void Unmap() {
		Bind();
		glUnmapBuffer(type);
	}

}
