module Engine.Transform;

import Engine.Core;
import Engine.Component;
import std.stdio;



class Transform  {
    mixin ComponentBase;
    @property ref vec3 Position()  {
        updateInvert = true;
        updatePos = true;
        return position;
    };

    @property ref vec3 Scale()() {
        updateInvert = true;
        updateScale = true;
        return scale;
    };

    
    @property ref vec3 Rotation()() {
        updateInvert = true;
        updateRot = true;
        return rotation;
    };

    vec3 position = vec3(0,0,0);
    vec3 rotation = vec3(0,0,0);
    vec3 scale = vec3(1,1,1);

    package mat4 matrix;
    package mat4 translateMatrix;
    package mat4 scaleMatrix;
    package mat4 rotateMatrix;
    package mat4 invertMatrix;
    package bool updateInvert = true;

    
    package bool updatePos = true;
    package bool updateRot = true;
    package bool updateScale = true;

    this() {

    }

    public void OnComponentAdd() {
        entity.transform_ = this;
    }

    mat4 Matrix()() {	
        bool recalculate = false;
        if (updateRot) {
            rotateMatrix = mat4.identity.rotatex(rotation.x).rotatey(rotation.y).rotatez(rotation.z);
            recalculate = true;
            updateRot = false;
        }	
        if (updateScale) {
            scaleMatrix = mat4.identity.scale(scale.x, scale.y, scale.z);
            recalculate = true;
            updateScale = false;
        }
        if (updatePos) {
            translateMatrix = mat4.identity.translation(position.x, position.y, position.z);
            recalculate = true;
            updatePos = false;
        }
        if (recalculate) {
            matrix = translateMatrix*rotateMatrix*scaleMatrix;
            updateInvert = true;
        }
        return matrix;
    }

    mat4 InvertedMatrix()() {
        if (updateInvert) {
            invertMatrix = Matrix().inverse;
        }
        updateInvert = false;
        return invertMatrix;
    }

    mat4 Matrix2() {	
        auto r = mat4.identity.rotatex(rotation.x).rotatey(rotation.y).rotatez(rotation.z);
        auto s = mat4.identity.scale(scale.x, scale.y, scale.z);
        auto t =  mat4.identity.translation(position.x, position.y, position.z);
        return t*r*s;
    }
    

}