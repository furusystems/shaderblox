package shaderblox.uniforms;
import snow.render.opengl.GL;

/**
 * Bool uniform
 * @author Andreas Rønning
 */
class UBool extends UniformBase<Bool> implements IAppliable  {
	public function new(name:String, index:Int, f:Bool = false) {
		super(name, index, f);
	}
	public inline function apply():Void {
		GL.uniform1i(location, data ? 1 : 0);
		dirty = false;
	}
}