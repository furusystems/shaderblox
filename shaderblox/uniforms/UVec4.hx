package shaderblox.uniforms;
#if snow
import snow.render.opengl.GL;
import falconer.utils.Vector3D;
#elseif lime
import lime.graphics.opengl.GL;
import lime.math.Vector4;
import lime.graphics.opengl.GLUniformLocation;
#end

using shaderblox.helpers.GLUniformLocationHelper;

/**
 * Vector4 float uniform
 * @author Andreas Rønning
 */
class UVec4 extends UniformBase<Vector4> implements IAppliable  {
	public function new(name:String, index:GLUniformLocation, x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0) {
		super(name, index, new Vector4(x, y, z, w));
	}
	public inline function apply():Void {
		GL.uniform4f(location, data.x, data.y, data.z, data.w);
		dirty = false;
	}
}