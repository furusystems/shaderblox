package shaderblox.uniforms;
#if snow
import snow.render.opengl.GL;
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
	public function new(name:String, index:Int) {
		super(name, index, null);
	}
	public inline function apply():Void {
		if (data == null || location==-1 ) return;
		GL.uniform1i(location, samplerIndex);
		var idx = GL.TEXTURE0 + samplerIndex;
		if (lastActiveTexture != idx) {
			GL.activeTexture(lastActiveTexture = idx);
			GL.enable(GL.TEXTURE_2D);
		}
		GL.bindTexture(GL.TEXTURE_2D, data);
		dirty = false;
	}
}