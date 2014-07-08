package shaderblox.uniforms;

/**
 * Generic uniform type
 * @author Andreas Rønning
 */
class UniformBase<T> {
	public var name:String;
	public var location:Int;
	public var data:T;
	function new(name:String, index:Int, data:T) {
		this.name = name;
		this.location = index;
		this.data = data;
	}
	public inline function set(data:T):T {
		return this.data = data;
	}
}