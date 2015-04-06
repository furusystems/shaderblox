package shaderblox.uniforms;
#if snow
import snow.modules.opengl.GL;
#elseif lime
import lime.gl.GL;
import lime.gl.GLTexture;
#end

/**
 * GLTexture uniform
 * @author Andreas Rønning
 */
class UTexture extends UniformBase<GLTexture> implements IAppliable  {
	public var samplerIndex:Int;
	static var lastActiveTexture:Int = -1;
	var cube:Bool;
	public var type:Int;
	public function new(name:String, index:Int, cube:Bool = false) {
		this.cube = cube;
		type = cube?GL.TEXTURE_CUBE_MAP:GL.TEXTURE_2D;
		super(name, index, null);
	}
	public inline function apply():Void {
		if (data == null || location==-1 ) return;
		var idx = GL.TEXTURE0 + samplerIndex;
		if (lastActiveTexture != idx) {
			GL.activeTexture(lastActiveTexture = idx);
		}
		GL.uniform1i(location, samplerIndex);
		GL.bindTexture(type, data);
		dirty = false;
	}
}