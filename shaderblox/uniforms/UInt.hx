package shaderblox.uniforms;
import snow.render.opengl.GL;

/**
 * Int uniform
 * @author Andreas Rønning
 */
class UInt extends UniformBase<Int> implements IAppliable  {
	public function new(name:String, index:Int, f:Int = 0) {
		super(name, index, f);
	}
	public inline function apply():Void {
		GL.uniform1i(location, data);
		dirty = false;
	}
}