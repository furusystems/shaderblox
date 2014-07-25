package shaderblox.uniforms;
#if snow
import snow.render.opengl.GL;
#elseif lime
import lime.gl.GL;
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
	public function new(name:String, index:Int, x:Float = 0, y:Float = 0) {
		var p = new Pt();
		p.x = x;
		p.y = y;
		super(name, index, p);
	}
	public inline function apply():Void {
		if(location!=-1) GL.uniform2f(location, data.x, data.y);
	}
}