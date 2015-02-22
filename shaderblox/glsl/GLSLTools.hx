//:TODO: globals functions don't currently exclude non-global scope which might be an issue for complex shaders with many consts embedded

package shaderblox.glsl;

using Lambda;

typedef GLSLGlobal = {?storageQualifier:String, ?precision:String, type:String, name:String, ?arraySize:Int};


interface INode<T>{
    public var contents:T;
    public function toString():String;
}

class StringNode implements INode<String>{
    public var contents:String;
    public function new(str:String = "")
        this.contents = str;

    public function toString()
        return contents;
}

class ScopeNode implements INode<Array<INode<Dynamic>>>{
    public var contents:Array<INode<Dynamic>>;
    public var openBracket = "";
    public var closeBracket = "";
    public function new(?brackets:String){
        this.contents = new Array<INode<Dynamic>>();
        if(brackets != null){
            this.openBracket = brackets.charAt(0);
            this.closeBracket = brackets.charAt(1);
        }
    }

    public inline function push(v:INode<Dynamic>) return contents.push(v);
    public function toString(){
        var str:String = openBracket;
        for(n in contents)
            str += n.toString();
        return str + closeBracket;
    }
}


//fairly primitive glsl parsing with regex
class GLSLTools {
	static var PRECISION_QUALIFIERS = ['lowp', 'mediump', 'highp'];
 	static var MAIN_FUNC_REGEX = new EReg('(?:\\s|^)(?:('+PRECISION_QUALIFIERS.join('|')+')\\s+)?(void)\\s+(main)\\s*\\([^\\)]*\\)\\s*\\{', 'gm');
 	static var STORAGE_QUALIFIERS = ['const', 'attribute', 'uniform', 'varying'];
 	static var STORAGE_QUALIFIER_TYPES = [
 		'const'     => ['bool','int','float','vec2','vec3','vec4','bvec2','bvec3','bvec4','ivec2','ivec3','ivec4','mat2','mat3','mat4'],
 		'attribute' => ['float','vec2','vec3','vec4','mat2','mat3','mat4'],
 		'uniform'   => ['bool','int','float','vec2','vec3','vec4','bvec2','bvec3','bvec4','ivec2','ivec3','ivec4','mat2','mat3','mat4','sampler2D','samplerCube'],
 		'varying'   => ['float','vec2','vec3','vec4','mat2','mat3','mat4']
 	];

 	// typedef CharacterRange = {
 	// 	var start:Int;
 	// 	var end:Int;
 	// }
 	//locateGlobal(src, {storageQualifier: 'const', type: 'int', name: 'PIXEL_SIZE'})
 	// static public function locateGlobal(src:String, global:GLSLGlobal):CharacterRange{
 	// 	if(global.storageQualifier == null) return null;

 	// 	var storageQualifier = global.storageQualifier;
 	// 	var types = [global.type];

  //   	var reg = new EReg(storageQualifier+'\\s+(('+PRECISION_QUALIFIERS.join('|')+')\\s+)?('+types.join('|')+')\\s+([^;]+)', 'gm');

		// return {start: 0, end: 0};
 	// }

    static function scopeExplode(src, openBracket:String, rightBracket:String, ?maxDepth:Int){

    }

 	//:todo: value should later be ConstType and have function toGLSL():String
 	static public function injectConstValue(src:String, name:String, value:Dynamic){
 		var storageQualifier = 'const';
 		var types = STORAGE_QUALIFIER_TYPES[storageQualifier];

    	var reg = new EReg(storageQualifier+'\\s+(('+PRECISION_QUALIFIERS.join('|')+')\\s+)?('+types.join('|')+')\\s+([^;]+)', 'gm');

    	if(!reg.match(src)) return false;
    	var definitionPos = reg.matchedPos();
    	trace(definitionPos);

    	var rawNamesStr = reg.matched(4);

        //#! need to scope string to ignore commas in more complex types

    	//find name in rawNamesStr
    	return true;
 	}


    static public function extractGlobals(src:String, ?storageQualifiers:Array<String>):Array<GLSLGlobal>{
    	if(storageQualifiers == null)
    		storageQualifiers = STORAGE_QUALIFIERS;

    	if(src == null) return [];

    	var str = stripComments(src);

    	var globals = new Array<GLSLGlobal>();

    	for (storageQualifier in storageQualifiers) {
    		var types = STORAGE_QUALIFIER_TYPES[storageQualifier];

    		//format: (precision)? (type) (name1 (= (value))?, name2 (= (value))?);
    		var reg = new EReg(storageQualifier+'\\s+(('+PRECISION_QUALIFIERS.join('|')+')\\s+)?('+types.join('|')+')\\s+([^;]+)', 'gm');
    		
    		while(reg.match(str)){
    	        var precision = reg.matched(2);
    	        var type = reg.matched(3);
    	        var rawNamesStr = reg.matched(4);

    	        //Extract comma separated names and array sizes (ie light1, light2 and name[size])
    	        //	also evaluate any initialization expressions (ie strength = 2.3)
    	        //	there is no mechanism for initializing arrays at declaration time from within a shader

    	        //format: (name) ([arraySize])? = (expression), ...
    	        var rName = ~/^\s*([\w\d_]+)\s*(\[(\d*)\])?\s*(=\s*(.+))?$/igm;
    	        for(rawName in rawNamesStr.split(',')){
    				if(!rName.match(rawName)) continue;//name does not conform

    	           	var global = {
    	           		storageQualifier: storageQualifier,
    	           		precision: precision,
    	           		type: type,
    	           		name: rName.matched(1),
    	           		arraySize: Std.parseInt(rName.matched(3))
    	           	};

    	           	//validity checks
    	           	//if storageQualifier is 'const', arraySize must be null because const requires initialization and arrays cannot be initialized here
    	           	//for all other storageQualifiers value must be null because these cannot be initialized

    	            globals.push(global);
    	        }

    	        str = reg.matchedRight();
    	    }

    	}

        return globals;
    }
	
	static public function stripComments(src:String):String {
		return (~/(?:\/\*(?:[\s\S]*?)\*\/)|(?:\/\/(?:.*)$)/igm).replace(src, '');//#1 = block comments, #2 = line comments
	}

	static public function unifyLineEndings(src:String):String {
		return StringTools.trim(src.split("\r").join("\n").split("\n\n").join("\n"));
	}

	static public function hasMain(src:String):Bool{
		if(src == null)return false;
		var str = stripComments(src);
		return MAIN_FUNC_REGEX.match(str);
	}

	static public function stripMain(src:String):String {
		if(src == null)return null;
		var str = src;
		var reg = MAIN_FUNC_REGEX;
        
        var matched = reg.match(str);
        if(!matched)return str;
        
        var remainingStr = reg.matchedRight();
        
        var mainEnd:Int = 0;
        //find closing bracket
        var open = 1;
        for(i in 0...remainingStr.length){
            var c = remainingStr.charAt(i);
            if(c=="{")open++;else if(c=="}")open--;
        	if(open==0){
                mainEnd = i+1;
                break;
            }
        }

		return reg.matchedLeft()+remainingStr.substring(mainEnd, remainingStr.length);
	}

	static function GLSLGlobalToString(g:GLSLGlobal):String{
    	return	(g.storageQualifier != null ? g.storageQualifier : '')+' '+
    			(g.precision != null ? g.precision : '')+' '+
    			g.type+' '+
    			g.name+
    			(g.arraySize != null ? '['+g.arraySize+']' : '')+';';

    }

}