package shaderblox.uniforms;
#if snow
import snow.render.opengl.GL;
#elseif lime
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLUniformLocation;

using shaderblox.helpers.GLUniformLocationHelper;
#end

/**
 * Bool uniform
 * @author Andreas Rønning
 */
class UBool extends UniformBase<Bool> implements IAppliable  {
	public function new(name:String, index:GLUniformLocation, f:Bool = false) {
		super(name, index, f);
	}
	public inline function apply():Void {
		GL.uniform1i(location, data ? 1 : 0);
		dirty = false;
	}
}