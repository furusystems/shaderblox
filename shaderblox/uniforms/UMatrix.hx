package shaderblox.uniforms;
#if snow
import snow.utils.Float32Array;
import snow.render.opengl.GL;
#elseif lime
import lime.gl.GL;
import lime.utils.Matrix3D;
#else
throw "Requires lime or snow";
#end

/**
 * Matrix3D uniform (not transposed)
 * @author Andreas Rønning
 */
class UMatrix extends UniformBase<Matrix3D> implements IAppliable {
	public function new(name:String, index:Int, ?m:Matrix3D) {
		if (m == null) m = new Matrix3D();
		super(name, index, m);
	}
	public inline function apply():Void {
		#if lime
		if (location != -1) {
			GL.uniformMatrix3D(location, false, data);
			dirty = false;
		}
		#elseif snow
		if (location != -1) {
			GL.uniformMatrix4fv(location, false, new Float32Array(data.rawData));
			dirty = false;
		}
		#end
	}
}