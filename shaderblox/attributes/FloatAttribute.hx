package shaderblox.attributes;

/**
 * ...
 * @author Andreas Rønning
 */
class FloatAttribute extends Attribute
{
	public var numFloats:Int;
	public function new(name:String, location:Int, nFloats:Int = 1) 
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