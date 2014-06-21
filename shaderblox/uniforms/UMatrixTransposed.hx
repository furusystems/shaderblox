package shaderblox.uniforms;
import lime.gl.GL;
import lime.utils.Matrix3D;

/**
 * ...
 * @author Andreas Rønning
 */
class UMatrixTransposed extends UniformBase<Matrix3D> implements IAppliable {
	public inline function new(index:Int, ?m:Matrix3D) {
		if (m == null) m = new Matrix3D();
		super(index, m);
	}
	inline function apply():Void {
		GL.uniformMatrix3D(this.location, true, this.data);
	}
}