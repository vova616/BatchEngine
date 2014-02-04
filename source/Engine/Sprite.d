module Engine.Sprite;

import Engine.Component;
import derelict.opengl3.gl;
import Engine.Texture;
import Engine.Core;
import Engine.Buffer;
import Engine.Batch;
import Engine.Input;
import Engine.Material;
import Engine.Shader;
import Engine.math;
import std.stdio;

class Sprite : Batchable {
	mixin ComponentBase;

	package
	vec4 _color = vec4(1,1,1,1);
	package
	BatchData* batch;
	Material _material;

	@property
	Material material() {
		return _material;
	};

	@property
	int vertecies() {
		return 4;	
	}
;
	@property
	int indecies() {
		return 6;	
	};
		
	@property
	ref
	vec4 color() {
		if (batch !is null) {
			batch.MarkCheck(BatchData.Type.Color);
		}
		return _color;
	}

	public
	void OnComponentAdd() {
		entity.sprite = this;
	}

	this(Material material) {
		this._material = material;
	}

	this(Texture texture) {
		this(texture.GetMaterial());
	}

	void OnBatchSetup(BatchData* data) {
		batch = data;
	}

	void UpdateBatch(vec3[] vertex, vec2[] uv, vec4[] color, uint[] index, uint indexPosition) {
		if (vertex !is null) {
			vertex[0] = vec3(-0.5f, -0.5f, 0.0f);
			vertex[1] = vec3(0.5f,  -0.5f, 0.0f);
			vertex[2] = vec3(0.5f,  0.5f, 0.0f);
			vertex[3] = vec3(-0.5f,  0.5f, 0.0f);
		}
		if (color !is null) {
			color[0] = _color;
			color[1] = _color;
			color[2] = _color;
			color[3] = _color;
		}
		if (uv !is null) {
			uv[0] = vec2(0,0);
			uv[1] = vec2(1,0);
			uv[2] = vec2(1,1);
			uv[3] = vec2(0,1);
		}
		if (index !is null) {
			index[0] = indexPosition;
			index[1] = indexPosition+1;
			index[2] = indexPosition+2;
			index[3] = indexPosition;
			index[4] = indexPosition+2;
			index[5] = indexPosition+3;
		}
	}

}

