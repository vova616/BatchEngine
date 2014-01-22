module Engine.Texture;

import Engine.Atlas;
import derelict.freeimage.freeimage;
import std.stdio;
import derelict.opengl3.gl;
import Engine.math;
import Engine.Buffer;
import Engine.Material;

struct UV {
	public float U1;
	public float V1;
	public float U2;
	public float V2;
}

interface ITexture {
	@property GLenum id();
	@property recti rect();
	@property ubyte pixelSize();
	@property GLenum format();

	package static GLuint currentTexture = -1;

	@property final int width() {
		return rect.max.x - rect.min.x;
	}

	@property final int height() {
		return rect.max.y - rect.min.y;
	}

	final void Bind() {
		if (id != currentTexture) {
			currentTexture = id;
			glBindTexture(GL_TEXTURE_2D,id);
		}
	}



}

class DynamicTexture : Texture {

	Buffer buffer;
	int nextIndex = 1;
	int index = 0;
	int pboMode = 2;

	this(ITexture texture) {
		super(texture);
		this.buffer = new Buffer(this.rect.Dx() * this.rect.Dy() * this.pixelSize,GL_PIXEL_UNPACK_BUFFER,GL_STREAM_DRAW);
	}

	final void Update(T)(void delegate(T[] arr) update) {
        buffer.Update(update);
		this.Bind();
		glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, rect.Dx(), rect.Dy(), format, GL_UNSIGNED_BYTE, null);
	}

	final void CopyToBuffer() {
		glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, rect.Dx(), rect.Dy(), format, GL_UNSIGNED_BYTE, null);
	}

}

class Texture : ITexture {
	@property GLenum id() { return _id;};
	@property recti rect() { return _rect;};
	@property ubyte pixelSize() { return _pixelSize;};
	@property GLenum format() { return _format; };

	package GLenum _id;
	package recti _rect;
	package ubyte _pixelSize;
	package GLenum _format;

	package Material material;

    package static immutable bool littleEndian;

	static this() {
		DerelictFI.load();
		littleEndian = cast(bool)FreeImage_IsLittleEndian();
	}

	final Material GetMaterial() {
		if (material is null) {
			material = new Material(this);
		}
		return material;
	}

	package this() {}

	this(ITexture texture) {
		this._id = texture.id;
		this._rect = texture.rect;
		this._pixelSize = texture.pixelSize;
		this._format = texture.format;
		//this._pixelType = texture.pixelType;
	}

	this(ubyte[] buffer, int width, int height) {
		this._rect = recti(width,height);
		this._pixelSize = 2;
		this._format = GL_RGBA;
		//generate an OpenGL texture ID for this texture
		glGenTextures(1, &_id);
		//bind to the new texture ID
		glBindTexture(GL_TEXTURE_2D, id);
	
		glTexImage2D(GL_TEXTURE_2D, 0, this._format, width, height,
					 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, cast(void*)buffer);

		SetFiltering(GL_LINEAR,GL_LINEAR);
	}

	this(int width, int height) {
		this._rect = recti(width,height);
		this._pixelSize = 4*4;
		this._format = GL_RGBA32F;
		//generate an OpenGL texture ID for this texture
		glGenTextures(1, &_id);
		//bind to the new texture ID
		glBindTexture(GL_TEXTURE_2D, id);

		glTexImage2D(GL_TEXTURE_2D, 0, this._format, width, height,
					 0, 0, GL_FLOAT, null);

		SetFiltering(GL_NEAREST,GL_NEAREST);
	}

	this(string filename) {
		auto fif = FreeImage_GetFileType(filename.ptr, 0);
		//if still unknown, try to guess the file format from the file extension
		if(fif == FIF_UNKNOWN) 
			fif = FreeImage_GetFIFFromFilename(filename.ptr);
		//if still unkown, return failure
		if(fif == FIF_UNKNOWN)
			throw new Exception("Unkown format " ~ filename);
		
		if(!FreeImage_FIFSupportsReading(fif)) {
			throw new Exception("Cannot read the file " ~ filename);
		}
		auto dib = FreeImage_Load(fif, filename.ptr, 0);
		if (dib == null) {
			throw new Exception("Cannot load the file " ~ filename);
		}
		
		scope(exit)  FreeImage_Unload(dib);
			
		//retrieve the image data
		auto pixels = FreeImage_GetBits(dib);
		
		//get the image width and height
		auto width = FreeImage_GetWidth(dib);
		auto height = FreeImage_GetHeight(dib);

		_rect = recti(width,height);

		//if this somehow one of these failed (they shouldn't), return failure
		if((pixels is null) || (width == 0) || (height == 0))
			throw new Exception("Unexcepted error there is no width/height/pixels.");

		auto colorType = FreeImage_GetColorType(dib);
		//generate an OpenGL texture ID for this texture
		glGenTextures(1, &_id);
		//bind to the new texture ID
		glBindTexture(GL_TEXTURE_2D, id);


		//store the texture data for OpenGL use
		switch(colorType) { 
			case FIC_RGB:
				this._format = GL_RGB;
				GLenum inFormat;
				if (littleEndian) {
					inFormat = GL_BGR;
				} else {
					inFormat = GL_RGB;
				}
				glTexImage2D(GL_TEXTURE_2D, 0, this._format, width, height,
							 0,inFormat, GL_UNSIGNED_BYTE, pixels);
				this._pixelSize = 3;
				break;
			case FIC_RGBALPHA:
				this._format = GL_RGBA;
				GLenum inFormat;
				if (littleEndian) {
					inFormat = GL_BGRA;
				} else {
					inFormat = GL_RGBA;
				}
				glTexImage2D(GL_TEXTURE_2D, 0, this._format, width, height,
							 0, inFormat, GL_UNSIGNED_BYTE, pixels);
				this._pixelSize = 4;
				break;
			default:
				throw new Exception("Cannot this handle pixel type.");
		}
	
		SetFiltering(GL_NEAREST,GL_NEAREST);	
	}

	UV RectUV(recti rect) {
		auto w = cast(double)width;
		auto h = cast(double)height;
		return UV((cast(double)rect.min.x)/w,
			(cast(double)rect.min.y)/h,
			(cast(double)rect.max.x)/w,
			(cast(double)rect.max.y)/h);
		//return vec2(cast(double)width = r.
	}

	void SetFiltering(GLenum mag, GLenum min) {		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, mag);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, min);
	}



}