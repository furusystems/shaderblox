package shaderblox.helpers;

import lime.graphics.opengl.GLUniformLocation;

class GLUniformLocationHelper{
	static public inline function isValid(u:GLUniformLocation){
		return	#if !js 
				(u >= 0);
				#else
				(u != null);
				#end
	}
}