package shaderblox;
import shaderblox.attributes.Attribute;
import snow.platform.native.render.opengl.GL.GLProgram;
import snow.platform.native.render.opengl.GL.GLShader;
import snow.render.opengl.GL;

/**
 * ...
 * @author Andreas Rønning
 */
class Shader
{
	public var uniformLocations:Map<String,Int>;
	public var attributes:Array<Attribute>;
	public var aStride:Int;
	public var vert:GLShader;
	public var frag:GLShader;
	public var prog:GLProgram;
	
	public var active:Bool;
	public var ready:Bool;
	
	public var vertSource:String;
	public var fragSource:String;
	
	public var numReferences:Int;
	public var name:String;
	public function new() 
	{
		attributes = [];
	}
	
	public function rebuild() {
		initFromSource(vertSource, fragSource);
	}
	
	public function initFromSource(vertSource:String, fragSource:String) {
		this.vertSource = vertSource;
		this.fragSource = fragSource;
		var vertexShader = GL.createShader (GL.VERTEX_SHADER);
		GL.shaderSource (vertexShader, vertSource);
		GL.compileShader (vertexShader);
		
		if (GL.getShaderParameter (vertexShader, GL.COMPILE_STATUS) == 0) {
			trace("Error compiling vertex shader: " + GL.getShaderInfoLog(vertexShader));
			trace("\n"+vertSource);
			throw "Error compiling vertex shader";
			
		}
		
		var fragmentShader = GL.createShader (GL.FRAGMENT_SHADER);
		GL.shaderSource (fragmentShader, fragSource);
		GL.compileShader (fragmentShader);
		
		if (GL.getShaderParameter (fragmentShader, GL.COMPILE_STATUS) == 0) {
			trace("Error compiling fragment shader: " + GL.getShaderInfoLog(fragmentShader)+"\n");
			var lines = fragSource.split("\n");
			var i = 0;
			for (l in lines) {
				trace((i++) + " - " + l);
			}
			throw "Error compiling fragment shader";
			
		}
		
		var shaderProgram = GL.createProgram ();
		GL.attachShader (shaderProgram, vertexShader);
		GL.attachShader (shaderProgram, fragmentShader);
		GL.linkProgram (shaderProgram);
		
		if (GL.getProgramParameter (shaderProgram, GL.LINK_STATUS) == 0) {
			throw "Unable to link the shader program.";
		}
		
		var numUniforms = GL.getProgramParameter(shaderProgram, GL.ACTIVE_UNIFORMS);
		uniformLocations = new Map<String, Int>();
		while (numUniforms-->0) {
			var uInfo = GL.getActiveUniform(shaderProgram, numUniforms);
			var loc:Int = cast GL.getUniformLocation(shaderProgram, uInfo.name);
			uniformLocations[uInfo.name] = loc;
		}
		var numAttributes = GL.getProgramParameter(shaderProgram, GL.ACTIVE_ATTRIBUTES);
		var attributeLocations:Map<String,Int> = new Map<String, Int>();
		while (numAttributes-->0) {
			var aInfo = GL.getActiveAttrib(shaderProgram, numAttributes);
			var loc:Int = cast GL.getAttribLocation(shaderProgram, aInfo.name);
			attributeLocations[aInfo.name] = loc;
		}
		
		vert = vertexShader;
		frag = fragmentShader;
		prog = shaderProgram;
		
		//TODO: Graceful handling of unused sampler uniforms.
		/**
		 * 1. Find every sampler/samplerCube uniform
		 * 2. For each sampler, assign a sampler index from 0 and up
		 * 3. Go through uniform locations, remove inactive samplers
		 * 4. Pack remaining active sampler
		 */
		
		//Validate attribute locations
		for (a in attributes) {
			var loc = attributeLocations.get(a.name);
			a.location = loc == null? -1:loc;
			if (a.location == -1) trace("WARNING(" + name + "): unused attribute '" + a.name +"'");
			#if (debug && !display) trace("Defined attribute "+a.name+" at "+a.location); #end
		}
		ready = true;
	}
	
	public function bind() {
		if (active) return;
		GL.useProgram(prog);
		setAttributes();
		active = true;
	}
	public function release() {
		if (!active) return;
		disableAttributes();
		active = false;
	}
	public function dispose() {
		GL.deleteShader(vert);
		GL.deleteShader(frag);
		GL.deleteProgram(prog);
		prog = null;
		vert = null;
		frag = null;
		ready = active = false;
	}
	public function setAttributes() 
	{
		var offset:Int = 0;
		for (i in 0...attributes.length) {
			var att = attributes[i];
			var location = att.location;
			if (location != -1) {
				GL.enableVertexAttribArray(location);
				GL.vertexAttribPointer (location, att.itemCount, att.type, false, aStride, offset);
			}
			offset += att.byteSize;
		}
	}
	public function disableAttributes() 
	{
		for (i in 0...attributes.length) {
			var idx = attributes[i].location;
			if (idx == -1) continue;
			GL.disableVertexAttribArray(idx);
		}
	}
	
}