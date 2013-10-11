module Engine.Camera;

import Engine.Component;
import Engine.Texture;
import Engine.Core;


class Camera : Component {
	// This will identify our vertex buffer

	package mat4 projection;

	this() {
		projection = mat4().orthographic(-Core.width/2, Core.width/2, -Core.height/2, Core.height/2, -1000, 10000);
	}

	mat4 Projection() {
		return projection;
	}

	mat4 View() {
		return transform.InvertedMatrix();
	}
}

