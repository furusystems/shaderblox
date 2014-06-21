package shaderblox.attributes;

/**
 * ...
 * @author Andreas Rønning
 */
class FloatAttribute
{
	public var numFloats:Int;
	public var byteSize:Int;
	public var location:Int;
	public var name:String;
	public function new(name:String, location:Int, ?nFloats:Int = 1) 
	{
		this.name = name;
		this.location = location;
		byteSize = nFloats * 4;
		numFloats = nFloats;
	}
	public function toString():String 
	{
		return "[FloatAttribute numFloats=" + numFloats + " byteSize=" + byteSize + " location=" + location + " name=" + name + "]";
	}
	
}