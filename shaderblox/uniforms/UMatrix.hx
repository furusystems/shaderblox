package shaderblox.uniforms;
import lime.gl.GL;
import lime.utils.Matrix3D;

/**
 * ...
 * @author Andreas Rønning
 */
class UMatrix extends UniformBase<Matrix3D> implements IAppliable {
	public inline function new(name:String, index:Int, ?m:Matrix3D) {
		if (m == null) m = new Matrix3D();
		super(name, index, m);
	}
	public inline function apply():Void {
		GL.uniformMatrix3D(this.location, false, this.data);
	}
}