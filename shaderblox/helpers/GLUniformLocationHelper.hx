package shaderblox.helpers;

#if snow
import snow.render.opengl.GL;
#elseif lime
import lime.graphics.opengl.GLUniformLocation;
#end

class GLUniformLocationHelper{
	static public inline function isValid(u:GLUniformLocation){
		return  #if !js (u >= 0); #else (u != null); #end
	}
}