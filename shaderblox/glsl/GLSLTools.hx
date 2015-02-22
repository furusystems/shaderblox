//:TODO: globals functions don't currently exclude non-global scope which might be an issue for complex shaders with many consts embedded

package shaderblox.glsl;

using Lambda;

typedef GLSLGlobal = {?storageQualifier:String, ?precision:String, type:String, name:String, ?arraySize:Int};


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

 	//:todo: value should be ConstType and have function toGLSL():String
 	static public function injectConstValue(src:String, name:String, value:Dynamic){
 		var storageQualifier = 'const';
 		var types = STORAGE_QUALIFIER_TYPES[storageQualifier];

    	var reg = new EReg(storageQualifier+'\\s+(('+PRECISION_QUALIFIERS.join('|')+')\\s+)?('+types.join('|')+')\\s+([^;]+)', 'gm');

        var str = stripComments(src);
    	while(reg.match(src)){
        	var definitionPos = reg.matchedPos();
        	trace(definitionPos);

        	var rawNamesStr = reg.matched(4);

            var rConstName = new EReg('\\s*('+name+')\\s*=', 'igm');//here initializer is required and there are no square brackets
            //rawNameStr is exploded by brackets so that ',' contained within are ignored
            var exploded = bracketExplode(rawNamesStr, "()");
           /* for(i in 0...exploded.contents.length){
                var n = exploded.contents[i];
                if(Std.is(n, StringNode)){

                    if(rConstName.match(n.toString())){ //check if current string matches const name pattern

                        //#! once a match has been found, we need to find the end of the initialization expression
                        //find initialization expression length
                        var terminatorLength = 0;
                        var terminatorFound = false;
                        for(j in i...exploded.contents.length){
                            var m = exploded.contents[j];
                            if(Std.is(m, StringNode)){
                                //#! search string for ,
                                if(m.toString().indexOf(',')==-1){
                                    //add index to terminator length
                                    terminatorFound = true;
                                    break;
                                }
                            }else{
                                //add node's string-length to length of initialization expression

                            }
                        }
                        if(!terminatorFound){
                            //terminator is total length
                        }

                    }

                }
            }*/

            //compress the layer and to a local-global-like transform to convert the compressed string position to the true position

            str = reg.matchedRight();    
        }

    	return false;
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

    static function bracketExplode(src, brackets:String /* eg: "{}" */){
        if(brackets.length != 2) return null;

        var open = brackets.charAt(0), close = brackets.charAt(1);

        var root = new ScopeNode();
        //scope source
        var scopeStack = new Array<ScopeNode>();
        var currentScope = root;
        var currentNode:INode<Dynamic> = null;
        var c, level = 0;
        for(i in 0...src.length){
            c = src.charAt(i);
            if(c==open){
                level++;
                var newScope = new ScopeNode(brackets);
                currentScope.push(newScope);
                
                scopeStack.push(currentScope);             
                currentScope = newScope;
                
                currentNode = currentScope;
            }else if(c==close){
                level--;
                currentScope = scopeStack.pop();                
                currentNode = currentScope;
            }else{
                if(!Std.is(currentNode, StringNode)){
                    currentNode = new StringNode();
                    currentScope.push(currentNode);
                }
                
                cast(currentNode, StringNode).contents += c;
            }
        }
                    
        return root;
    }

}

private interface INode<T>{
    public var contents:T;
    public function toString():String;
}

private class StringNode implements INode<String>{
    public var contents:String;
    public function new(str:String = "")
        this.contents = str;

    public function toString()
        return contents;
}

private class ScopeNode implements INode<Array<INode<Dynamic>>>{
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