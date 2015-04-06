package shaderblox;
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
	var ready:Bool;
	public var textures:Array<UTexture>;
	
	var uniforms:Array<IAppliable>;
	var attributes:Array<Attribute>;
	var name:String;
	var numTextures:Int;
	var aStride:Int;
	
	function new() {
		init();
	}
	
	function init() {
		textures = [];
		uniforms = [];
		attributes = [];
		name = ("" + Type.getClass(this)).split(".").pop();
		createProperties();
	}
	
	function createProperties() { }
	
	public function destroy() { }
	
	function validateUniformLocations(shdr:Shader) {
		//Validate uniform locations
		var count = uniforms.length;
		var removeList:Array<IAppliable> = [];
		numTextures = 0;
		textures = [];
		for (u in uniforms) {
			var loc = shdr.uniformLocations.get(u.name);
			if (Std.is(u, UTexture)) {
				var t:UTexture = cast u;
				t.samplerIndex = numTextures++;
				textures[t.samplerIndex] = t;
			}
			if (loc != null) {				
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
		ready = true;
	}
	
	public function activate() {}
	
	public function deactivate() {}
	
	public function setAttributes() { }
	
	public function setUniforms() 
	{
		for (u in uniforms) {
			u.apply();
		}
	}
	
	public function toString():String {
		return "[Shader(" + name+", attributes:" + attributes.length + ", uniforms:" + uniforms.length + ")]";
	}
}