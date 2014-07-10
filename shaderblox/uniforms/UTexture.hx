package shaderblox.uniforms;
import lime.gl.GL;
import lime.gl.GLTexture;

/**
 * GLTexture uniform
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
		var idx = GL.TEXTURE0 + samplerIndex;
		//if (RenderState.ACTIVE_TEXTURE_UNIT != idx) {
			GL.activeTexture(idx);
			GL.enable(GL.TEXTURE_2D);
		//}
		//RenderState.ACTIVE_TEXTURE_UNIT = idx;
		GL.bindTexture(GL.TEXTURE_2D, data);
	}
}