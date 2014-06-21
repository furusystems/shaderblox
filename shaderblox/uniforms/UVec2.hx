package shaderblox.uniforms;
import lime.gl.GL;

/**
 * ...
 * @author Andreas Rønning
 */
private class Pt {
	public var x:Float;
	public var y:Float;
	public inline function new() { }
}
class UVec2 extends UniformBase<Pt> implements IAppliable  {
	public function new(name:String, index:Int, x:Float = 0, y:Float = 0) {
		var p = new Pt();
		p.x = x;
		p.y = y;
		super(name, index, p);
	}
	public inline function apply():Void {
		GL.uniform2f(location, data.x, data.y);
	}
}