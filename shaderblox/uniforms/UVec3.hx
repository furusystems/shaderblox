package shaderblox.uniforms;
import shaderblox.geom.Vector3D;
#if snow
import snow.modules.opengl.GL;
#elseif lime
import lime.gl.GL;
#end

/**
 * Vector3 float uniform
 * @author Andreas Rønning
 */
class UVec3 extends UniformBase<Vector3D> implements IAppliable {
	public function new(name:String, index:Int, x:Float = 0, y:Float = 0, z:Float = 0) {
		super(name, index, new Vector3D(x, y, z));
	}
	public inline function apply():Void {
		if (location != -1) {
			GL.uniform3f(location, data.x, data.y, data.z);
			dirty = false;
		}
	}
}