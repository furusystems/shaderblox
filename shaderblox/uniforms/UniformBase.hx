package shaderblox.uniforms;

/**
 * ...
 * @author Andreas Rønning
 */
class UniformBase<T> {
	public var name:String;
	public var location:Int;
	public var data:T;
	public function new(name:String, index:Int, data:T) {
		this.name = name;
		this.location = index;
		this.data = data;
	}
}