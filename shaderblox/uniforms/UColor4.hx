package shaderblox.uniforms;

/**
 * ...
 * @author Andreas Rønning
 */
abstract UColor4(UVec4) from UVec4 to UVec4
{

	public inline function new(name:String, index:Int) 
	{
		this = new UVec4(name, index);
	}
	
	public inline function apply():Void {
		this.apply();
	}
	
	public var r(get, set):Float;
	public var g(get, set):Float;
	public var b(get, set):Float;
	public var a(get, set):Float;
	
	inline function get_r():Float { return this.data.x; };
	inline function get_g():Float { return this.data.y; };
	inline function get_b():Float { return this.data.z; };
	inline function get_a():Float { return this.data.w; };
	
	inline function set_r(v:Float):Float { return this.data.x=v; };
	inline function set_g(v:Float):Float { return this.data.y=v; };
	inline function set_b(v:Float):Float { return this.data.z=v; };
	inline function set_a(v:Float):Float { return this.data.w=v; };
	
	public inline function setFromHex(color:Int):UColor4 {
		a = (color >> 24) / 255;
		r = (color >> 16 & 0xFF) / 255;
		g = (color >>  8 & 0xFF) / 255;
		b = (color & 0xFF) / 255;
		return this;
	}
	public inline function toHex():Int {
		return Std.int(a * 255) << 24 | Std.int(r * 255) << 16 | Std.int(g * 255) << 8 | Std.int(b * 255);
	}
	public inline function copyFrom(other:UColor4):Void {
		r = other.r;
		g = other.g;
		b = other.b;
		a = 1;
	}
	
}