package shaderblox.uniforms;
#if snow
import snow.modules.opengl.GL;
import shaderblox.geom.Vector3D;
#elseif lime
import lime.graphics.opengl.GL;
import lime.math.Vector4;
import lime.graphics.opengl.GLUniformLocation;
typedef Vector3D = lime.math.Vector4;
#end

using shaderblox.helpers.GLUniformLocationHelper;

/**
 * Vector3 float uniform
 * @author Andreas Rønning
 */
class UVec3 extends UniformBase<Vector3D> implements IAppliable {
	public function new(name:String, index:GLUniformLocation, x:Float = 0, y:Float = 0, z:Float = 0) {
		super(name, index, new Vector3D(x, y, z));
	}
	public inline function apply():Void {
		GL.uniform3f(location, data.x, data.y, data.z);
		dirty = false;
	}
}