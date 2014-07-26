package shaderblox.uniforms;
#if snow
import snow.render.opengl.GL;
#elseif lime
import lime.gl.GL;
#end

/**
 * Float uniform
 * @author Andreas Rønning
 */
class UFloat extends UniformBase<Float> implements IAppliable  {
	public function new(name:String, index:Int, f:Float = 0.0) {
		super(name, index, f);
	}
	public inline function apply():Void {
		if (location != -1) {
			GL.uniform1f(location, data);
			dirty = false;
		}
	}
}