package shaderblox.uniforms;
#if snow
import snow.render.opengl.GL;
#elseif lime
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLUniformLocation;
import lime.math.Vector2;

using shaderblox.helpers.GLUniformLocationHelper;
#end

/**
 * Vector2 float uniform
 * @author Andreas Rønning
 */
class UVec2 extends UniformBase<Vector2> implements IAppliable  {
	public function new(name:String, index:GLUniformLocation, x:Float = 0, y:Float = 0) {
		super(name, index, new Vector2(x, y));
	}
	public inline function apply():Void {
		GL.uniform2f(location, data.x, data.y);
		dirty = false;
	}
}