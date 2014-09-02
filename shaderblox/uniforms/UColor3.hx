package shaderblox.uniforms;

/**
 * ...
 * @author Andreas Rønning
 */
abstract UColor3(UVec3) from UVec3 to UVec3
{

	public inline function new(name:String, index:Int) 
	{
		this = new UVec3(name, index);
	}
	public inline function apply():Void {
		this.apply();
	}
	
	public var r(get, set):Float;
	public var g(get, set):Float;
	public var b(get, set):Float;
	
	inline function get_r():Float { return this.data.x; };
	inline function get_g():Float { return this.data.y; };
	inline function get_b():Float { return this.data.z; };
	
	inline function set_r(v:Float):Float { return this.data.x = v; };
	inline function set_g(v:Float):Float { return this.data.y = v; };
	inline function set_b(v:Float):Float { return this.data.z = v; };
	
	public inline function setFromHex(color:Int):UColor3 {
		r = (color >> 16) / 255;
		g = (color >> 8 & 0xFF) / 255;
		b = (color & 0xFF) / 255;
		return this;
	}
	public inline function toHex():Int {
		return Std.int(r * 255) << 16 | Std.int(g * 255) << 8 | Std.int(b * 255);
	}
	public inline function copyFrom(other:UColor3):Void {
		r = other.r;
		g = other.g;
		b = other.b;
	}
	
}