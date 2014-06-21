package shaderblox.uniforms;
import lime.gl.GL;

/**
 * ...
 * @author Andreas Rønning
 */
class UFloat extends UniformBase<Float> implements IAppliable  {
	public inline function new(name:String, index:Int, f:Float = 0.0) {
		super(name, index, f);
	}
	public inline function apply():Void {
		GL.uniform1f(this.location, this.data);
	}
}