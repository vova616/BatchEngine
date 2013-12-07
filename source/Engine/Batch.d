module Engine.Batch;

import std.stdio;
import derelict.opengl3.gl;
import Engine.Buffer;
import gl3n.linalg;
import Engine.Component;
import Engine.Texture;
import Engine.Material;
import Engine.Core;
import engine = Engine.Entity;
import std.parallelism;
import std.bitmanip;
import Engine.Allocator;
import std.datetime;

struct BatchData {
	enum Type {
		Transform,
		UV,
		Color,
		Vertex,
		Index,
		Size,
	}

	this(Batch batch, engine.Entity entity, Batchable batchable,int vertexIndex,int indexIndex,int vertexCount,int indexCount,int totalVertexCount,int totalIndexCount) {
		this.batch = batch;
		this.entity = entity;
		this.batchable = batchable;
		this.vertexIndex = vertexIndex;
		this.indexIndex = indexIndex;
		this.vertexCount = vertexCount;
		this.indexCount = indexCount;
		this.totalIndexCount = totalIndexCount;
		this.totalVertexCount = totalVertexCount;
		updateTransform = true;
		updateUV = true;
		updateColor = true;
		updateVertex = true;
		updateIndex = true;
	}

	Batch batch;
	engine.Entity entity;
	Batchable batchable;
	int vertexIndex;
	int indexIndex;
	int vertexCount;
	int indexCount;

	int totalVertexCount;
	int totalIndexCount;

/*
	bool updateColor;
	bool updateTransform;
	bool updateUV;
	bool updateVertex;
	bool updateIndex;
	bool updateSize;
	*/
	package mixin(bitfields!(
			bool, "updateTransform",    1,
			bool, "updateUV",    1,
			bool, "updateColor",    1,
			bool, "updateVertex", 1,
			bool, "updateIndex", 1,
			bool, "updateSize", 1,
			int, "", 2));
	
	void MarkCheck(const Type[] types...) {
		foreach (t;types) {
			switch(t) {
				case Type.Transform:
					updateTransform = true;
					break;
				case Type.UV:
					updateUV = true;
					break;
				case Type.Color:
					updateColor = true;
					break;
				case Type.Vertex:
					updateVertex = true;
					break;
				case Type.Index:
					updateIndex = true;
					break;
				case Type.Size:
					if (updateSize)
						return;
					batch.CheckBatches ~= &this;
					this.updateSize = true;
					break;
				default:
					break;
			}	
		}
	}

	final void Update()(vec3[] vertex,vec2[] uv, vec4[] color,uint[] index, uint indexPosition) {
		int call = 4;
		if (!updateUV) {
			uv = null;
			call--;
		}
		if (!updateColor) {
			color = null;
			call--;
		}
		if (!updateVertex) {
			vertex = null;
			call--;
		}
		if (!updateIndex) {
			index = null;
			call--;
		}
		if (call > 0) {	
			batchable.UpdateBatch(vertex,uv,color,index,indexPosition);
			updateUV = false;
			updateIndex = false;
			updateVertex = false;
			updateColor = false;
		}
	}

	final void ForceUpdate()(vec3[] vertex,vec2[] uv, vec4[] color,uint[] index, uint indexPosition) {
		batchable.UpdateBatch(vertex,uv,color,index,indexPosition);
	}
}

class Batch {

	Buffer vertex;
	Buffer uv;
	Buffer color;
	Buffer index;
	Buffer matrix;

	//ChunkAllocator!(BatchData, 100) batchAllocator;

	BatchData*[] Batches;
	BatchData*[] CheckBatches;
	BatchData[] DeleteBatches;
	int totalIndecies;
	Material material;

	int vertexIndex;
	int indexIndex;
	int vsize;
	int isize;
	int deletedIndecies = 0;
	bool resize;

	this(int size,Material material) {
		Batches = new BatchData*[size];
		CheckBatches = new BatchData*[4];  
		DeleteBatches = new BatchData[4];
		DeleteBatches.length = 0;
		CheckBatches.length = 0;
		this.vsize = size*4;
		this.isize = size*6;
		Batches.length = 0;
		vertex = new Buffer(this.vsize*vec3.sizeof, GL_ARRAY_BUFFER,GL_STREAM_DRAW);
		color = new Buffer(this.vsize*vec4.sizeof, GL_ARRAY_BUFFER,GL_STREAM_DRAW);
		uv = new Buffer(this.vsize*vec2.sizeof,GL_ARRAY_BUFFER,GL_STREAM_DRAW);
		index  = new Buffer(this.isize*int.sizeof,GL_ELEMENT_ARRAY_BUFFER,GL_STREAM_DRAW);
		matrix = new Buffer(this.vsize*mat4.sizeof,GL_ARRAY_BUFFER,GL_STREAM_DRAW);
		this.material = material;
	}


	void Rebuild() {
		vertexIndex = 0;
		indexIndex = 0;
		foreach (batch; Batches) {
			batch.vertexIndex = vertexIndex;
			batch.indexIndex = indexIndex;
			vertexIndex += batch.totalVertexCount;
			indexIndex += batch.totalIndexCount;
		}
	}	

	void Add(engine.Entity entity, Batchable batch) {
		if (vertexIndex + batch.vertecies > vsize || 
			indexIndex + batch.indecies > isize ) {
			vsize = 2 * (vertexIndex + batch.vertecies);
			isize = 2 * (indexIndex + batch.indecies);
			resize = true;
		}		
		//auto b = batchAllocator.allocate();
		auto b = new BatchData(this,entity,batch,vertexIndex,indexIndex,batch.vertecies,batch.indecies,batch.vertecies,batch.indecies);
		//*b = BatchData(this,entity,batch,vertexIndex,indexIndex,batch.vertecies,batch.indecies,batch.vertecies,batch.indecies);
		Batches ~= b;
		vertexIndex += batch.vertecies;
		indexIndex += batch.indecies;
		batch.OnBatchSetup(b);
	}


	void Resize(BatchData* batch) {
		if (vertexIndex + batch.totalVertexCount > vsize || 
			indexIndex + batch.totalIndexCount > isize ) {	
			vsize = 2 * (vertexIndex + batch.totalVertexCount);
			isize = 2 * (indexIndex + batch.totalIndexCount);
			resize = true;
		} else {
			batch.vertexIndex = vertexIndex;
			batch.indexIndex = indexIndex;
			vertexIndex += batch.totalVertexCount;
			indexIndex += batch.totalIndexCount;
		}
	}

	 void Update() {
		 //Checking for resizing/deactiving/etc
		 for (int i = 0;i<CheckBatches.length;i++) {
			 auto b = CheckBatches[i];
			 b.updateSize = false;

			 b.updateUV = true;
			 b.updateColor = true;
			 b.updateIndex = true;
			 b.updateVertex = true;

			 b.vertexCount = b.batchable.vertecies;
			 b.indexCount = b.batchable.indecies;
			 auto tic = b.totalIndexCount;
		  	 auto ii = b.indexIndex;
		  	 //Increase vertex size if needed
			 if (b.vertexCount > b.totalVertexCount || b.indexCount > b.totalIndexCount) {
				 b.totalVertexCount = b.vertexCount * 2;
				 b.totalIndexCount = b.indexCount * 2;
				 Resize(b);
			 }	
			 //Delete batch data if needed
			 if (!resize ) {
				DeleteBatches ~= BatchData(null,null,null,0,ii,0,0,0,tic);
			 }
		 }			
		 CheckBatches.length = 0;
	
		 //Resizing & rebuilding
		 bool updateAll = false;
		 if (resize) {
		 	 DeleteBatches.length = 0;
			 vertex.Resize(vsize*vec3.sizeof);
			 color.Resize(vsize*vec4.sizeof);
			 uv.Resize(vsize*vec2.sizeof);
			 index.Resize(isize*int.sizeof);
			 matrix.Resize(vsize*mat4.sizeof);
			 resize = false;
			 updateAll = true;
			 Rebuild();
		 }
		
		
		 StopWatch t1;
		 StopWatch t2;
		 t2.start();
		 t1.start();
		 auto varr = vertex.Map!vec3(0, vertexIndex*vec3.sizeof);
		 auto carr = color.Map!vec4(0, vertexIndex*vec4.sizeof);
		 auto uvarr = uv.Map!vec2(0, vertexIndex*vec2.sizeof);
		 auto iarr = index.Map!uint(0, indexIndex*uint.sizeof);
		 auto matrcies = matrix.Map!(vec3[3])(0, vertexIndex*(vec3[3]).sizeof);
		 t1.stop();
		// writeln("buffer map", cast(double)t1.peek().nsecs / 1000000);
	
		 uint vindex = 0;
		 totalIndecies = 0;
		 scope(exit) {
			 t1.start();
			 vertex.Unmap();
			 color.Unmap();
			 uv.Unmap();
			 index.Unmap();
			 matrix.Unmap();
			 t1.stop();
			 t2.stop();
			// writeln("buffer unmap", cast(double)t1.peek().nsecs / 1000000);
			// writeln("batch update", cast(double)t2.peek().nsecs / 1000000);
		 }

		//deactiving batches		
		for (int i = 0;i<DeleteBatches.length;i++) {
			auto e = &DeleteBatches[i];
			iarr[e.indexIndex..e.indexIndex+e.totalIndexCount] = 0;
		}	
		DeleteBatches.length = 0;


		//Multithreaded batch updates.
		auto ti = taskPool.workerLocalStorage(0);
		if (updateAll) {
			foreach( e; parallel(Batches)) {
				auto indx = e.vertexIndex;
				auto max = indx+e.vertexCount;	
				e.ForceUpdate(varr[indx..max],uvarr[indx..max],carr[indx..max],iarr[e.indexIndex..e.indexIndex+e.indexCount],indx);
				
				//if (e.updateTransform || 1 == 1) {
				auto t = e.entity.transform;
				auto p = t.position;
				auto r = t.rotation;
				auto s = t.scale;
				
				for (;indx<max;indx++) {
					matrcies[indx][0] = p;
					matrcies[indx][1] = r;
					matrcies[indx][2] = s;
				}
			}
		} else {	
			foreach( e; parallel(Batches)) {
				
				auto indx = e.vertexIndex;
				auto max = indx+e.vertexCount;	
				e.Update(varr[indx..max],uvarr[indx..max],carr[indx..max],iarr[e.indexIndex..e.indexIndex+e.indexCount],indx);

				//if (e.updateTransform || 1 == 1) {
				auto t = e.entity.transform;
				auto p = t.position;
				auto r = t.rotation;
				auto s = t.scale;
				
				for (;indx<max;indx++) {
					matrcies[indx][0] = p;
					matrcies[indx][1] = r;
					matrcies[indx][2] = s;
				}
			}
		}


		totalIndecies = indexIndex;


		/*
		foreach(ref e; Core.entities) {
			if (e.sprite !is null && e.sprite.texture.id == texture.id) {
				int vertecies,indecies;
				e.sprite.Sizes(vertecies,indecies);
				e.sprite.UpdateBatch(varr,uvarr,carr,iarr,vindex);
				vindex += vertecies;
				totalIndecies += indecies;
				varr = varr[vertecies..$];
				carr = carr[vertecies..$];
				uvarr = uvarr[vertecies..$];
				iarr = iarr[indecies..$];

				auto t = e.Transform;
				auto p = t.Position;
				auto r = t.Rotation;
				auto s = t.Scale;
				
				for (int i=0;i<vertecies;i++) {
					matrcies[i] = [p,r,s];
				}
				matrcies = matrcies[vertecies..$];
			}
		}

		auto mat = this.Transform.Matrix();
		vertex[0] = (mat*vec4(-0.5f, -0.5f, 0.0f,1)).xyz;
		vertex[1] = (mat*vec4(0.5f,  -0.5f, 0.0f,1)).xyz;
		vertex[2] = (mat*vec4(0.5f,  0.5f, 0.0f,1)).xyz;
		vertex[3] = (mat*vec4(-0.5f,  0.5f, 0.0f,1)).xyz;
		*/
	}

	 void Draw() {
		StopWatch t1;
		t1.start();
		material.render(this);
		t1.stop();
		//writeln("batch Draw", cast(double)t1.peek().nsecs / 1000000);
	}
}

interface Batchable {
	@property Material material();
	@property int vertecies();
	@property int indecies();
	
	void OnBatchSetup( BatchData* data);
	void UpdateBatch(vec3[] vertex, vec2[] uv, vec4[] color, uint[] index, uint indexPosition);
}
