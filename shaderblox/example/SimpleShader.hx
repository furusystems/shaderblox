package shaderblox.example;
import shaderblox.ShaderBase;

/**
 * "Hello world" shader example
 * @author Andreas Rønning
 */

@:vert('
	attribute vec2 aVertexPosition;
	void main(void) {
		gl_Position = vec4(aVertexPosition,0.0,1.0);
	}
')

@:frag('
	uniform vec3 uColor;
	void main(void)
	{
		gl_FragColor = vec4(uColor,1.0);
	}
')
class SimpleShader extends ShaderBase {}