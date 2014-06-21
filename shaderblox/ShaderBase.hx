package shaderblox;
import shaderblox.uniforms.FloatAttribute;
import shaderblox.uniforms.IAppliable;
import shaderblox.uniforms.UTexture;
import lime.gl.GL;
import lime.gl.GLProgram;
import lime.gl.GLShader;
/**
 * ...
 * @author Andreas Rønning
 */
@:shaderNoBuild
@:autoBuild(croissant.renderer.ShaderBuilder.build()) 
class ShaderBase
{	
	public var active:Bool;
	var uniforms:Array<IAppliable>;
	var uniformMap:Map<String, IAppliable>;
	var attributes:Array<FloatAttribute>;
	var aStride:Int;
	var name:String;
	var vert:GLShader;
	var frag:GLShader;
	var prog:GLProgram;
	var ready:Bool;
	var numTextures:Int;
	
	public function new() {
		uniforms = [];
		uniformMap = new Map<String,IAppliable>();
		attributes = [];
		name = (""+Type.getClass(this)).split(".").pop();
	}
	
	public inline function getUniformByName(str:String):IAppliable {
		return uniformMap[str];
	}
	
	public function create():Void {
	}
	
	public function destroy():Void {
		GL.deleteShader(vert);
		GL.deleteShader(frag);
		GL.deleteProgram(prog);
		ready = false;
	}
	
	function initFromSource(vertSource:String, fragSource:String) {
		trace("vert: " + vertSource);
		trace("frag: " + fragSource);
		var vertexShader = GL.createShader (GL.VERTEX_SHADER);
		numTextures = 0;
		GL.shaderSource (vertexShader, vertSource);
		GL.compileShader (vertexShader);
		
		if (GL.getShaderParameter (vertexShader, GL.COMPILE_STATUS) == 0) {
			trace("Error compiling vertex shader: "+GL.getShaderInfoLog(vertexShader));
			throw "Error compiling vertex shader";
			
		}
		
		var fragmentShader = GL.createShader (GL.FRAGMENT_SHADER);
		GL.shaderSource (fragmentShader, fragSource);
		GL.compileShader (fragmentShader);
		
		if (GL.getShaderParameter (fragmentShader, GL.COMPILE_STATUS) == 0) {
			trace("Error compiling fragment shader: "+GL.getShaderInfoLog(fragmentShader));
			throw "Error compiling fragment shader";
			
		}
		
		var shaderProgram = GL.createProgram ();
		GL.attachShader (shaderProgram, vertexShader);
		GL.attachShader (shaderProgram, fragmentShader);
		GL.linkProgram (shaderProgram);
		
		if (GL.getProgramParameter (shaderProgram, GL.LINK_STATUS) == 0) {
			throw "Unable to initialize the shader program.";
		}
		
		var numUniforms = GL.getProgramParameter(shaderProgram, GL.ACTIVE_UNIFORMS);
		var uniformLocations:Map<String,Int> = new Map<String, Int>();
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
		
		//Validate uniform locations
		for (u in uniforms) {
			uniformMap[u.name] = u;
			var loc = uniformLocations.get(u.name);
			u.location = loc == null? -1:loc;
			if (u.location == -1) trace("WARNING(" + name + "): unused uniform '" + u.name +"'");
			if (Std.is(u, UTexture) && u.location != -1) {
				cast(u, UTexture).samplerIndex = numTextures++;
			}
			#if debug trace("Defined uniform "+u.name+" at "+u.location); #end
		}
		
		//Validate attribute locations
		for (a in attributes) {
			var loc = attributeLocations.get(a.name);
			a.location = loc == null? -1:loc;
			if (a.location == -1) trace("WARNING(" + name + "): unused attribute '" + a.name +"'");
			#if debug trace("Defined attribute "+a.name+" at "+a.location); #end
		}
	}
	
	public inline function activate(initUniforms:Bool = true, initAttribs:Bool = false):Void {
		if (active) return;
		if (!ready) create();
		GL.useProgram(prog);
		if (initUniforms) setUniforms();
		if (initAttribs) setAttributes();
		active = true;
	}
	public inline function deactivate():Void {
		if (!active) return;
		active = false;
		disableAttributes();
		GL.useProgram(null);
	}
	
	public inline function setUniforms() 
	{
		for (u in uniforms) {
			if (u.location == -1) continue;
			u.apply();
		}
	}
	public function setAttributes() 
	{
		for (i in 0...attributes.length) {
			var idx = attributes[i].location;
			if (idx == -1) continue;
			
			GL.enableVertexAttribArray(idx);
			GL.vertexAttribPointer (idx, attributes[i].numFloats, GL.FLOAT, false, aStride, i*attributes[i].byteSize);
		}
	}
	function disableAttributes() 
	{
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