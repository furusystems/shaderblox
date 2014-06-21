package shaderblox.uniforms;

/**
 * All Uniforms are IAppliable.
 * "apply()" is used to upload updated uniform values to the GPU.
 * @author Andreas Rønning
 */

interface IAppliable 
{
	var location:Int;
	var name:String;
	function apply():Void;
}