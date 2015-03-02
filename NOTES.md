[GLSL Language Spec](http://www.khronos.org/files/opengles_shading_language.pdf)


Parser Ideas:
	#1 Emscripten
	- Alter emscripten's jsifier.js to output haxe
	- Use emscripten to compile the glsl reference compiler to haxe from llvm bytecode

	#2 Port stack.gl code






Future:

- Const should have haxe-based type
- basic parsing into something similar to an AST by extending bracketExplode.
- the AST is used to produce a glsl string on demand and makes for easier, more robust source modifications

- maybe rename superclass main to super(), and others super.func_name?
	so we can do 
	void main(){
		super();
		...
	}

#Shaderblox Defines

--------------

Using const helps do away with type inference

Treat as equivalent to uniforms but requires recompiling when changed

--------------

uniform setting can be handled by some combination of abstracts and internal utypes

const must be different:
	
	I think the nicest design is to extract the global consts, present them as class fields and swap out the values at runtime when they change
	This requires runtime search and replace however, which is trickier than perpending the consts, but hopefully not too much tricker

	The class fields should have getters and setters that trigger the recompile
	
	We'll need to be careful when defining fields incase they're already defined on a superclass

	The class fields could be dynamic or have underlying types that reflect their nature and handle to-from-haxe conversions such as @:from {x, y, z}
	
	! Executing glsl as haxe won't work for more complex types
		How do we handle this?
			const vec2 gravity = vec2(0, 9.8)*4.0;
		One option is to make constants write-only 

	Later: Should we override new to pass constants as the argument? 


[DONE]shader base variables should be prepended with _ to prevent conflicts with glsl variables

pragma extracting could do with a do-over, it probably shouldn't be handling the work of including the source