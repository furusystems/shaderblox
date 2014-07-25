package shaderblox.uniforms;
#if lime
import lime.utils.Matrix3D;
import lime.gl.GL;
#elseif snow
import falconer.utils.Matrix3D;
import snow.render.opengl.GL;
#end

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
		if(location!=-1) GL.uniformMatrix3D(location, true, data);
	}
}