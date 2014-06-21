package shaderblox.uniforms;
import lime.gl.GL;
import lime.utils.Vector3D;

/**
 * ...
 * @author Andreas Rønning
 */
class UVec4 extends UniformBase<Vector3D> implements IAppliable  {
	public inline function new(name:String, index:Int, x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0) {
		super(name, index, new Vector3D(x, y, z, w));
	}
	public inline function apply():Void {
		GL.uniform4f(this.location, this.data.x, this.data.y, this.data.z, this.data.w);
	}
}