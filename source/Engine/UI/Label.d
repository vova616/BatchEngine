module Engine.UI.Label;

import Engine.Component;
import Engine.Batch;
import Engine.Material;
import Engine.math;
import Engine.Font;
import Engine.Core;

class Label : Batchable {
	mixin ComponentBase;
	// This will identify our vertex buffer
	string text;
	Font font;
	package
	vec4 _color = vec4(1,1,1,1);


	Material _material;

	@property
	Material material() {
		return _material;
	}

		
	@property
	ref
	vec4 color() {
		if (batchData !is null) {
			batchData.MarkCheck(BatchData.Type.Color);
		}
		return _color;
	}

	package
	int actualSize;
	package
	BatchData* batchData;

	this(Font f,string text) {
		this.text = text;
		font = f;
		_material = font.Atlas.GetMaterial();
		SetText(text);
	}

	void OnBatchSetup(BatchData* data) {
		batchData = data;
	}
	
	@property
	int vertecies() {
		return actualSize*4;	
	}
;
	@property
	int indecies() {
		return actualSize*6;	
	};

	vec2 GetPixelSize(string text ) {
		auto index = 0;
		vec2 size = vec2(0,0);
		foreach ( chr; text) {
			auto spaceMult = 1;

			auto letterInfoPTR = chr in font.Map;
			if (letterInfoPTR is null) {
				size.x += 1;
				continue;
			}
			auto letterInfo = *letterInfoPTR;

			size.x += letterInfo.XAdvance * spaceMult;
			/*
			yratio := letterInfo.PlaneHeight
			ygrid := letterInfo.YGrid
			if yratio < 0 {
			yratio = -yratio
			}
			if ygrid < 0 {
			ygrid = -ygrid
			}

			if yratio+ygrid > height {
			height = yratio + ygrid
			}
			*/
			size.y = 1;
		}
		return size;
	}

	void SetText(string text) {
		this.text = text;
		auto oldSize = actualSize;
		actualSize = 0;
		foreach( chr; text) {
			auto letterInfo = chr in font.Map;
			if (letterInfo !is null) {
				actualSize++;
			}
		}
		if (batchData !is null) {
			batchData.MarkCheck(BatchData.Type.UV, BatchData.Type.Vertex);
			if ( oldSize != actualSize) {
				batchData.MarkCheck(BatchData.Type.Size);
			}
		}
	}

	void UpdateBatch(vec3[] vertexData, vec2[] uvData, vec4[] colorData, uint[] indexData, uint indexPosition) {

		if (vertexData is null && uvData is null && indexData is null) {
			if (colorData !is null) {
				colorData[] =  _color;
			}
			return;
		} 
		float space = 0;
		float spaceMult = 1;
		int index = 0;

		auto size = GetPixelSize(text);
		foreach( chr; text) {
			auto letterInfo = chr in font.Map;
			if (letterInfo is null) {
				space += 0.5;
				continue;
			}
			auto yratio = letterInfo.RelativeHeight;
			auto xratio = letterInfo.RelativeWidth;
			auto ygrid = -(size.y / 2) +  (letterInfo.YOffset);
			auto xgrid = -(size.x / 2) + (letterInfo.XOffset) + space;

			space += letterInfo.XAdvance * spaceMult;
			auto uv = font.Atlas.RectUV(letterInfo.AtlasRect);

			if (vertexData !is null) {
				vertexData[index*4+0] =  vec3(xgrid,ygrid,1);
				vertexData[index*4+1] =  vec3((xratio) + xgrid,ygrid,1);
				vertexData[index*4+2] =  vec3((xratio) + xgrid, (yratio) + ygrid,1);
				vertexData[index*4+3] =  vec3(xgrid,(yratio) + ygrid,1);
			}

			if (colorData !is null) {
				colorData[index*4+0] =  _color;
				colorData[index*4+1] =  _color;
				colorData[index*4+2] =  _color;
				colorData[index*4+3] =  _color;
			}

			if (uvData !is null) {
				uvData[index*4+0] = vec2(uv.U1,uv.V1);
				uvData[index*4+1] = vec2(uv.U2,uv.V1);
				uvData[index*4+2] = vec2(uv.U2,uv.V2);
				uvData[index*4+3] = vec2(uv.U1,uv.V2);
			}

			if (indexData !is null) {
				indexData[index*6+0] = indexPosition+(index*4);
				indexData[index*6+1] = indexPosition+(index*4)+1;
				indexData[index*6+2] = indexPosition+(index*4)+2;
				indexData[index*6+3] = indexPosition+(index*4);
				indexData[index*6+4] = indexPosition+(index*4)+2;
				indexData[index*6+5] = indexPosition+(index*4)+3;
			}

			index++;
		}
	}

}

