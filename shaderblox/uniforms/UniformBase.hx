package shaderblox.uniforms;

/**
 * Generic uniform type
 * @author Andreas Rønning
 */
@:generic @:remove class UniformBase<T> {
	public var name:String;
	public var location:Int;
	public var data:T;
	public var dirty:Bool;
	function new(name:String, index:Int, data:T) {
		this.name = name;
		this.location = index;
		this.data = data;
		dirty = true;
	}
	public inline function set(data:T):T {
		setDirty();
		return this.data = data;
	}
	public inline function setDirty() {
		dirty = true;
	}
}