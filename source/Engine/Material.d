module Engine.Material;

import Engine.Shader;
import Engine.Texture;
import Engine.Batch;
import Engine.Renderer;
import Engine.Core;

class Material {
	@property Shader shader() {
		return _shader;	
	};
	@property ITexture texture() {
		return _texture;	
	};
	@property Renderer renderer() {
		return _renderer;	
	};

	bool changed;
	
	Shader _shader;
	ITexture _texture;
	Renderer _renderer;

	this(ITexture texture) {
		_shader = Core.shader;
		_texture = texture;
		_renderer = defaultRenderer;
	}

	final void render(Batch batch) {
		if (renderer !is null) {
			renderer()(batch);
		}
	}
		
	override bool opEquals(Object mato) {
		Material mat = cast(Material)mato;
		if (this is mat)
			return false;	
		if (shader !is mat.shader)
			return false;
		if (texture !is null && mat.texture !is null) {
			if (texture.id != mat.texture.id)
				return false;
		} else {
			if (texture !is mat.texture)
				return false;
		}
		if (renderer != mat.renderer)
			return false;
		return true;
	}	
}


