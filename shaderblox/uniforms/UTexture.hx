package shaderblox.uniforms;
import com.furusystems.flywheel.display.rendering.lime.resources.TextureHandle;
import lime.gl.GL;

/**
 * ...
 * @author Andreas Rønning
 */
class UTexture extends UniformBase<TextureHandle> implements IAppliable  {
	public var samplerIndex:Int;
	public inline function new(name:String, index:Int) {
		super(name, index);
	}
	public inline function apply():Void {
		if (data == null) return;
		if (!data.acquired) data.acquire();
		GL.uniform1i(location, samplerIndex);
		GL.activeTexture(GL.TEXTURE0 + samplerIndex);
		GL.enable(GL.TEXTURE_2D);
		GL.bindTexture(GL.TEXTURE_2D, data.tex.tex);
	}
}