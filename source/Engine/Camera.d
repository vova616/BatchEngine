module Engine.Camera;

import Engine.CStorage;
import Engine.Texture;
import Engine.Core;
import Engine.math;
import Engine.Input;

class Camera  {
	mixin ComponentBase;
	// This will identify our vertex buffer

	package mat4 projection;

	float size = 1;
	recti rect;
	recti realRect;
	vec2i  center;

	this() {
		UpdateResolution();
	}

	mat4 Projection() {
		return projection;
	}

	//Mouse world position
	vec2 MouseWorldPosition() {
		auto v = MouseLocalPosition();
		return ScreenToWorld(v.x, v.y);
	}

	//Takes a point on the screen and turns it into point on world
	vec2 ScreenToWorld(float x, float y)  {
		auto p = transform.position;
		return vec2(p.x + x,p.y + y);
		//return (vec4(x,y,0,1) * transform.Matrix()).xy;
	}

	//Mouse local position
	vec2 MouseLocalPosition() {
		auto p = Input.MousePosition();
		p *= size;
		p.x += realRect.min.x;
		p.y = realRect.max.y-p.y;
		return p;
	}

	recti bounds() {
		auto r = realRect;
		r.add(vec2i(cast(int)transform.position.x,cast(int)transform.position.y));
		return r;
	}

	//Updates the Projection
	void UpdateResolution() {
		rect.min.x = -(Core.width) / 2;
		rect.max.x = (Core.width) / 2;
		rect.min.y = -(Core.height) / 2;
		rect.max.y = (Core.height) / 2;

		realRect.min.x = center.x - (center.x - rect.min.x);
		realRect.max.x = center.x - (center.x - rect.max.x);
		realRect.min.y = center.y - (center.y - rect.min.y);
		realRect.max.y = center.y - (center.y - rect.max.y);

		realRect.min.x = cast(int)(center.x - (center.x-rect.min.x)*size);
		realRect.max.x = cast(int)(center.x - (center.x-rect.max.x)*size);
		realRect.min.y = cast(int)(center.y - (center.y-rect.min.y)*size);
		realRect.max.y = cast(int)(center.y - (center.y-rect.max.y)*size);

		projection = mat4().orthographic(realRect.min.x, realRect.max.x, realRect.min.y, realRect.max.y, -100000, 100000);
	}

	mat4 View() {
		return transform.InvertedMatrix();
	}
}

