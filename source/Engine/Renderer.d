module Engine.Renderer;

import Engine.Batch;
import derelict.opengl3.gl;
import Engine.Core;

alias void function(Batch batch) Renderer;

Renderer defaultRenderer = &_defaultRenderer;

private static const final void _defaultRenderer(Batch batch) {
	auto shader = batch.material.shader;
	shader.Use();

	auto vertexAttrib = shader.Attributes["vertex"];
	auto uvAttrib = shader.Attributes["uv"];
	auto colorAttrib = shader.Attributes["color"];
	auto modelsAttrib = shader.Attributes["models"];

	glBindBuffer(GL_ARRAY_BUFFER, batch.vertex);
	glEnableVertexAttribArray(vertexAttrib.location);
	glVertexAttribPointer(
						  vertexAttrib.location,    // attribute    
						  3,                  // size
						  GL_FLOAT,           // type
						  GL_FALSE,           // normalized?
						  0,                  // stride
						  null                // array buffer offset
							  );	
	glBindBuffer(GL_ARRAY_BUFFER, batch.uv);
	glEnableVertexAttribArray(uvAttrib.location);
	glVertexAttribPointer(
						  uvAttrib.location,       // attribute 
						  2,                  // size
						  GL_FLOAT,           // type
						  GL_FALSE,           // normalized?
						  0,                  // stride
						  null                // array buffer offset
							  );	
	glBindBuffer(GL_ARRAY_BUFFER, batch.color);
	glEnableVertexAttribArray(colorAttrib.location);
	glVertexAttribPointer(
						  colorAttrib.location,        // attribute 
						  4,                  // size
						  GL_FLOAT,           // type
						  GL_FALSE,           // normalized?
						  0,                  // stride
						  null                // array buffer offset
							  );	

	glBindBuffer(GL_ARRAY_BUFFER, batch.matrix);
	glEnableVertexAttribArray(modelsAttrib.location);
	glVertexAttribPointer(
						  modelsAttrib.location,        // attribute 
						  3,                  // size
						  GL_FLOAT,           // type
						  GL_FALSE,           // normalized?
						  3*3*4,                  // stride
						  null                // array buffer offset
							  );	
	glEnableVertexAttribArray(modelsAttrib.location+1);
	glVertexAttribPointer(
						  modelsAttrib.location+1,        // attribute 
						  3,                  // size
						  GL_FLOAT,           // type
						  GL_FALSE,           // normalized?
						  3*3*4,                 // stride
						  cast(void*)(3*4)                // array buffer offset
							  );
	glEnableVertexAttribArray(modelsAttrib.location+2);
	glVertexAttribPointer(
						  modelsAttrib.location+2,        // attribute
						  3,                  // size
						  GL_FLOAT,           // type
						  GL_FALSE,           // normalized?
						  3*3*4,                  // stride
						  cast(void*)(6*4)               // array buffer offset
							  );



	batch.material.texture.Bind();
	glActiveTexture(GL_TEXTURE0);
	shader.Attributes["texture"].Set(0);
	shader.Attributes["projection"].Set(Core.camera.Projection());
	shader.Attributes["view"].Set(Core.camera.View());
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, batch.index);
	glDrawElements(GL_TRIANGLES, batch.totalIndecies, GL_UNSIGNED_INT, null);
}
