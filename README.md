Shaderblox
==========

Compile-time GLSL shader tools for Haxe/Lime

----------

Shaderblox is an alternative approach to building and maintaining GLSL shaders for use with Haxe and Lime, and probably OpenFL as well with some typedef magic.

It stems from an urge to strong type the bindings between a shader as seen by the GPU and the Haxe software layer that interacts with it. For instance, in our game engine we had a renderer interface that needed to rely on certain vertex attributes and uniforms to exist within each shader, and without strong typing and compile time errors, this caused some heartache for me.

Shaderblox is intended to meet the following goals:

- Compile-time parsing of shader source into strong typed classes with typed fields for attributes and uniforms.
- Inheritance-based shader building, with one shader inheriting attributes, uniforms, methods etc from another.
- #pragma tools for including external files (since writing inline shader source isn't super comfortable).  
- Generated methods for uploading uniforms and setting vertex attribute pointers.

With shaderblox, a shader incompatible with the rendering framework will cause compile time exceptions, meaning shader authors and framework engineers should have radically fewer ways to screw with one another.

## Caveats ##
1. Compiletime means swapping out shaders after the build is done is no longer possible: Shaders are as much a part of the compiled code as any class, rather than an external resource.
2. Shader source validation is only done once the source is actually compiled on the GPU itself, which can only occur runtime. 
3. GLSL parsing is currently *very* unsophisticated, looking specifically for attribute and uniform declarations and not much else.
4. Work in progress.. Open source.. etc etc. This is a personal project and it's constantly liable to change.

## Example ##

Shader types are defined with metadata, and built with macros. This simple shader is included with the source.
	
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

Note that instead of writing the source inline, as in this case, you could use this approach:

	@:vert('#pragma include("path/to/my/shader.vert")')

This external file will be loaded in at compiletime (as well as display-time, giving dynamic code completion as the external source is updated). You can of course liberally use the pragma include to build shaders whichever way you want.

The following source is a variation of the typical "hello triangle" using the SimpleShader example included with the source.

	package ;
	import haxe.Timer;
	import lime.gl.GL;
	import lime.gl.GLBuffer;
	import lime.Lime;
	import lime.utils.Float32Array;
	import shaderblox.example.SimpleShader;
	
	
	class Main {
		var lime:Lime;
		var shader:SimpleShader;
		var vbuf:GLBuffer;
		
		public function new () {
		}
		
		public function ready (lime:Lime):Void {
			this.lime = lime;
			
			vbuf = GL.createBuffer();
			var vertices:Array<Float> = [
			   0.0,  0.5,
			   0.5, -0.5,
			  -0.5, -0.5
			];
			
			GL.bindBuffer(GL.ARRAY_BUFFER, vbuf);
			GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(vertices), GL.STATIC_DRAW);
			GL.bindBuffer(GL.ARRAY_BUFFER, null);
			
			shader = new SimpleShader();
			shader.create(); //Create builds, validates attribs/uniforms and uploads. Should do this as part of load, or when context is lost.
		}
		
		inline function uSin(t:Float):Float {
			return Math.sin(t) * 0.5 + 0.5;
		}
		
		public function render ():Void {
			GL.viewport (0, 0, lime.config.width, lime.config.height);
			GL.clearColor (1.0, 1.0, 1.0, 1.0);
			GL.clear (GL.COLOR_BUFFER_BIT);
			
			//Set some wobbly color values on our vec3 uniform
			shader.uColor.data.x = uSin(Timer.stamp());
			shader.uColor.data.y = uSin(Timer.stamp()*2);
			shader.uColor.data.z = uSin(Timer.stamp()*3);
			
			//Set our shader as current.
			shader.activate();  
			//Note that by default, activate uploads uniform values, but does not set vertex attribute pointers (which needs to be repeated every buffer bind anyway)
			
			GL.bindBuffer(GL.ARRAY_BUFFER, vbuf); //Bind our vbo..
			
			//Set the vertex attribute pointers into the current vertex buffer object...
			shader.setAttributes(); 
			
			//Draw our triangle...
			GL.drawArrays(GL.TRIANGLE_FAN, 0, 3); 
			
			//..and clean up (important)
			shader.deactivate(); 
		}	
	}
