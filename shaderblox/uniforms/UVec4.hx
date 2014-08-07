package shaderblox.uniforms;
#if snow
import snow.render.opengl.GL;
import falconer.utils.Vector3D;
#elseif lime
import lime.graphics.opengl.GL;
import lime.utils.Vector3D;
import lime.graphics.opengl.GLUniformLocation;

using shaderblox.helpers.GLUniformLocationHelper;
#end

/**
 * Vector4 float uniform
 * @author Andreas Rønning
 */
class UVec4 extends UniformBase<Vector3D> implements IAppliable  {
	public function new(name:String, index:GLUniformLocation, x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0) {
		super(name, index, new Vector3D(x, y, z, w));
	}
	public inline function apply():Void {
		if (location.isValid()) {
			GL.uniform4f(location, data.x, data.y, data.z, data.w);
			dirty = false;
		}
	}
}