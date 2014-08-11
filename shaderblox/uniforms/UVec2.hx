package shaderblox.uniforms;
#if snow
import snow.render.opengl.GL;
#elseif lime
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLUniformLocation;

using shaderblox.helpers.GLUniformLocationHelper;
#end

/**
 * Vector2 float uniform
 * @author Andreas Rønning
 */
#if flywheel
private typedef Pt = com.furusystems.flywheel.geom.Vector2D;
#else
private class Pt {
	public var x:Float;
	public var y:Float;
	public inline function new() { }
}
#end
class UVec2 extends UniformBase<Pt> implements IAppliable  {
	public function new(name:String, index:GLUniformLocation, x:Float = 0, y:Float = 0) {
		var p = new Pt();
		p.x = x;
		p.y = y;
		super(name, index, p);
	}
	public inline function apply():Void {
		if (location.isValid()) {
			GL.uniform2f(location, data.x, data.y);
			dirty = false;
		}
	}
}