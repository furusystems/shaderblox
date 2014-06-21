package shaderblox.uniforms;
import lime.gl.GL;
import lime.utils.Matrix3D;

/**
 * Transposed Matrix3D uniform
 * @author Andreas Rønning
 */
class UMatrixTransposed extends UniformBase<Matrix3D> implements IAppliable {
	public function new(index:Int, ?m:Matrix3D) {
		if (m == null) m = new Matrix3D();
		super(index, m);
	}
	public inline function apply():Void {
		GL.uniformMatrix3D(location, true, data);
	}
}