package shaderblox.uniforms;
import lime.gl.GL;
import lime.gl.GLTexture;

/**
 * ...
 * @author Andreas Rønning
 */
class UTexture extends UniformBase<GLTexture> implements IAppliable  {
	public var samplerIndex:Int;
	public function new(name:String, index:Int) {
		super(name, index, null);
	}
	public inline function apply():Void {
		if (data == null) return;
		GL.uniform1i(location, samplerIndex);
		GL.activeTexture(GL.TEXTURE0 + samplerIndex);
		GL.enable(GL.TEXTURE_2D);
		GL.bindTexture(GL.TEXTURE_2D, data);
	}
}