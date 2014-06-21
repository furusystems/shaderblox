package shaderblox.uniforms;

/**
 * @author Andreas Rønning
 */

interface IAppliable 
{
	var location:Int;
	var name:String;
	function apply():Void;
}