package shaderblox;
#if snow
import snow.render.opengl.GL;
#elseif lime
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GLUniformLocation;
using shaderblox.helpers.GLUniformLocationHelper;
#end
import shaderblox.attributes.Attribute;
import shaderblox.uniforms.IAppliable;
import shaderblox.uniforms.UTexture;

/**
 * Base shader type. Extend this to define new shader objects.
 * Subclasses of ShaderBase must define shader source metadata. 
 * See example/SimpleShader.hx.
 * @author Andreas Rønning
 */

@:autoBuild(shaderblox.macro.ShaderBuilder.build()) 
class ShaderBase
{	
	public var active:Bool;
	var uniforms:Array<IAppliable>;
	var attributes:Array<Attribute>;
	public var textures:Array<UTexture>;
	var aStride:Int;
	var name:String;
	var vert:GLShader;
	var frag:GLShader;
	var prog:GLProgram;
	var ready:Bool;
	var numTextures:Int;
	
	public function new() {
		textures = [];
		uniforms = [];
		attributes = [];
		name = ("" + Type.getClass(this)).split(".").pop();
		createProperties();
	}
	
	private function createProperties():Void { }
	
	public function create():Void { }
	
	public function destroy():Void {
		trace("Destroying " + this);
		GL.deleteShader(vert);
		GL.deleteShader(frag);
		GL.deleteProgram(prog);
		prog = null;
		vert = null;
		frag = null;
		ready = false;
	}
	
	function initFromSource(vertSource:String, fragSource:String) {
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
			throw "Unable to initialize the shader program.\n"+GL.getProgramInfoLog(shaderProgram);
		}
		
		var numUniforms = GL.getProgramParameter(shaderProgram, GL.ACTIVE_UNIFORMS);
		var uniformLocations:Map<String,GLUniformLocation> = new Map<String, GLUniformLocation>();
		while (numUniforms-->0) {
			var uInfo = GL.getActiveUniform(shaderProgram, numUniforms);
			var loc = GL.getUniformLocation(shaderProgram, uInfo.name);
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
		
		//Validate uniform locations
		var count = uniforms.length;
		var removeList:Array<IAppliable> = [];
		numTextures = 0;
		textures = [];
		for (u in uniforms) {
			var loc = uniformLocations.get(u.name);
			if (Std.is(u, UTexture)) {
				var t:UTexture = cast u;
				t.samplerIndex = numTextures++;
				textures[t.samplerIndex] = t;
			}
			if (loc.isValid()) {				
				u.location = loc;
				#if (debug && !display) trace("Defined uniform "+u.name+" at "+u.location); #end
			}else {
				removeList.push(u);
				trace("WARNING(" + name + "): unused uniform '" + u.name +"'");
			}
		}
		while (removeList.length > 0) {
			uniforms.remove(removeList.pop());
		}
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
	}
	
	public function activate(initUniforms:Bool = true, initAttribs:Bool = false):Void {
		if (active) {
			if (initUniforms) setUniforms();
			if (initAttribs) setAttributes();
			return;
		}
		if (!ready) create();
		GL.useProgram(prog);
		if (initUniforms) setUniforms();
		if (initAttribs) setAttributes();
		active = true;
	}
	
	public function deactivate():Void {
		if (!active) return;
		active = false;
		disableAttributes();
		GL.useProgram(null);
	}
	
	public inline function setUniforms() {
		for (u in uniforms) {
			u.apply();
		}
	}
	public inline function setAttributes() {
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
	function disableAttributes() {
		for (i in 0...attributes.length) {
			var idx = attributes[i].location;
			if (idx == -1) continue;
			GL.disableVertexAttribArray(idx);
		}
	}
	public function toString():String {
		return "[Shader(" + name+", attributes:" + attributes.length + ", uniforms:" + uniforms.length + ")]";
	}
}