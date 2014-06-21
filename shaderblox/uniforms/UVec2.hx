package shaderblox.uniforms;
import com.furusystems.flywheel.geom.Vector2D;
import lime.gl.GL;

/**
 * ...
 * @author Andreas Rønning
 */
class UVec2 extends UniformBase<Vector2D> implements IAppliable  {
	public inline function new(name:String, index:Int, x:Float = 0, y:Float = 0) {
		super(name, index, new Vector2D(x, y));
	}
	public inline function apply():Void {
		GL.uniform2f(this.location, this.data.x, this.data.y);
	}
}