package shaderblox.macro;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.Ref;
import haxe.rtti.Meta;
using Lambda;

/**
 * ...
 * @author Andreas Rønning
 */
private typedef FieldDef = {index:Null<Int>, typeName:String, fieldName:String, extrainfo:Dynamic };
private typedef AttribDef = {index:Int, typeName:String, fieldName:String, itemCount:Int };
private typedef GLSLGlobal = {?storageQualifier:String, ?precision:String, type:String, name:String, ?arraySize:Int};
class ShaderBuilder
{
	#if macro
	
	static var uniformFields:Array<FieldDef>;
	static var attributeFields:Array<AttribDef>;

	static inline var GL_FLOAT:Int = 0x1406;
	static inline var GL_INT:Int = 0x1404;

	static function getSources(type:ClassType):Array<String> {
		var meta = type.meta.get();
		var out = [];
		var str:String;
		for (i in meta.array()) {
			switch(i.name) {
				case ":vert":
					str = getString(i.params[0]);
					str = pragmas(unifyLineEndings(str));
					out[0] = str;
				case ":frag":
					str = getString(i.params[0]);
					str = pragmas(unifyLineEndings(str));
					out[1] = str;
			}
		}
		return out;
	}
	
	public static function build():Array<Field> {
		var type = Context.getLocalClass().get();

		//handle build-metas
		for (f in type.meta.get().array()) {
			if (f.name == ":shaderNoBuild") return null;
		}
		
		uniformFields = [];
		attributeFields = [];

		var position = Context.currentPos();

		//get current class sources, taking care of overriding main()
		var localSources:Array<String> = getSources(Context.getLocalClass().get());
		var localVertSource = localSources[0];
		var localFragSource = localSources[1];
		
		// -- Process Sources --
		#if debug
		trace("Building " + Context.getLocalClass());
		#end
		var sources:Array<Array<String>> = [];
		
		//get super class sources
		var t2 = type;
		while (t2.superClass != null) {
			t2 = t2.superClass.t.get();
			if (t2.superClass != null) {
				#if debug
				trace("\tIncluding: " + t2.name);
				#end
				sources.unshift(getSources(t2));
			}
		}

		//add local sources after super class so as to override anything beneath
		sources.push(localSources);

		//strip comments from sources
		for (i in 0...sources.length) {
			var s = sources[i];
			if(s[0]==null)s[0]="";
			if(s[1]==null)s[1]="";
			s[0] = stripComments(s[0]);
			s[1] = stripComments(s[1]);
		}

		//find highest level class with main
		var highestMainVert:Int = -1;
		var highestMainFrag:Int = -1;
		for (i in 0...sources.length) {
			var s = sources[i];
			if(hasMain(s[0]))
				highestMainVert = i;

			if(hasMain(s[1]))
				highestMainFrag = i;
		}

		//strip main from source if not highest
		for (i in 0...sources.length) {
			var s = sources[i];

			if(i<highestMainVert)
				s[0] = stripMain(s[0]);
			if(i<highestMainFrag)
				s[1] = stripMain(s[1]);
		}

		// -- Assemble complete source --
		var vertSource = "";
		var fragSource = "";

		var defaultESPrecision = "\n#ifdef GL_ES\nprecision mediump float;\n#endif\n";
		vertSource += defaultESPrecision;
		fragSource += defaultESPrecision;

		for(i in 0...sources.length){
			var s = sources[i];
			vertSource += "\n"+s[0]+"\n";
			fragSource += "\n"+s[1]+"\n";
		}

		// -- Add assembled glsl strings to class as fields --
		var fields = Context.getBuildFields();

		buildSourceGetters(position, fields, vertSource, fragSource);

		// -- Add fields to class from local glsl --
		//vert
		if(localVertSource!=""){
			buildConsts(position, fields, localVertSource);
			buildUniforms(position, fields, localVertSource);
			buildAttributes(position, fields, localVertSource);
		}else {
			throw "No vert source";
		}
		//frag
		if(localFragSource!=""){
			buildConsts(position, fields, localFragSource);
			buildUniforms(position, fields, localFragSource);
		}else {
			throw "No frag source";
		}

		//override create() and createProperties() with some boilerplate #! needs refactoring
		buildOverrides(fields);

		var finalFields = buildFieldInitializers(fields);
		return finalFields;
	}
	
	static function buildSourceGetters(position, fields:Array<Field>, vertSource, fragSource){
		var vertGetter = {
			name: "get_"+"_vertSource",
			doc: null,
			meta: [],
			access: [APrivate, AOverride],
			kind: FFun({
					args:[],
					params:[],
					ret: macro : String,
					expr: macro{
						return $v{vertSource};
					}
			}),
			pos: Context.currentPos()
		}

		var fragGetter = {
			name: "get_"+"_fragSource",
			doc: null,
			meta: [],
			access: [APrivate, AOverride],
			kind: FFun({
					args:[],
					params:[],
					ret: macro : String,
					expr: macro{
						return $v{fragSource};
					}
			}),
			pos: Context.currentPos()
		}

		fields.push(vertGetter);
		fields.push(fragGetter);
	}

	static function buildConsts(position, fields, src){
		var consts = extractGLSLGlobals(src, ['const']);
		for(c in consts){
			//create const field
			//when field changes, the shader should update const value and recompile 
			
			//#! check if defined already

			//public var (CONSTANT):Dynamic = (value);
			var constField = {
				name: c.name,
				doc: null,
				meta: [],
				access: [APublic],
				kind: FProp("null","set",macro : Dynamic, null),
				pos: Context.currentPos()
			}

			//public var set_(CONSTANT) (value:Dynamic){ // sets constant value, calls update shader }
			var constSetter = {
				name: "set_"+c.name,
				doc: null,
				meta: [],
				access: [APrivate],
				kind: FFun({
						args:[{
								name: 'value',
								type: macro : Dynamic,
								opt: null,
								value: null
						}],
						params:[],
						ret: null,
						expr: macro{
							trace("hey, set works");
							Reflect.setField(this, $v{c.name}, value);
							return value;
						}
					
				}),
				pos: Context.currentPos()
			}

			fields.push(constField);
			fields.push(constSetter);

			var printer = new haxe.macro.Printer();
			trace(printer.printField(constField));
			trace(printer.printField(constSetter));
		}
	}

	static function buildAttributes(position, fields:Array<Field>, src:String) {
		var attributes = extractGLSLGlobals(src, ['attribute']);
		for(a in attributes)
			buildAttribute(position, fields, a);
	}

	static function buildUniforms(position, fields:Array<Field>, src:String) {
		var uniforms = extractGLSLGlobals(src, ['uniform']);
		for(u in uniforms)
			buildUniform(position, fields, u);
	}
	
	static function buildAttribute(position, fields, attribute:GLSLGlobal):Void {
		//Avoid field redefinitions
		if (checkIfFieldDefined(attribute.name)) return;
		
		for (existing in attributeFields) {
			if (existing.fieldName == attribute.name) return; 
		}
		var pack = ["shaderblox", "attributes"];
		var itemCount:Int = 0;
		var itemType:Int = -1;
		switch(attribute.type) {
			case "float":
				itemCount = 1;
				itemType = GL_FLOAT;
			case "vec2":
				itemCount = 2;
				itemType = GL_FLOAT;
			case "vec3":
				itemCount = 3;
				itemType = GL_FLOAT;
			case "vec4":
				itemCount = 4;
				itemType = GL_FLOAT;
			default:
				throw "Unknown attribute type: " + attribute.type;
		}
		var attribClassName:String = switch(itemType) {
			case GL_FLOAT:
				"FloatAttribute";
			default:
				throw "Unknown attribute type: " + itemType;
		}
		var type = { pack : pack, name : attribClassName, params : [], sub : null };
		var fld = {
				name : attribute.name, 
				doc : null, 
				meta : [], 
				access : [APublic], 
				kind : FVar(TPath(type), null), 
				pos : position 
			};
		fields.push(fld);
		var f = { index:attributeFields.length, fieldName: fld.name, typeName:pack.join(".") + "." + attribClassName, itemCount:itemCount };
		attributeFields.push(f);
	}

	static function buildUniform(position, fields, uniform:GLSLGlobal) {
		if (checkIfFieldDefined(uniform.name)) return;
		
		for (existing in uniformFields) {
			if (existing.fieldName == uniform.name) return; 
		}

		var pack = ["shaderblox", "uniforms"];
		var type = { pack : pack, name : "UMatrix", params : [], sub : null };
		var extrainfo:Dynamic = null;
		switch(uniform.type) {
			case "samplerCube":
				type.name = "UTexture";
				extrainfo = true;
			case "sampler2D":
				type.name = "UTexture";
				extrainfo = false;
			case "mat4":
				type.name = "UMatrix";
			case "bool":
				type.name = "UBool";
			case "int":
				type.name = "UInt";
			case "float":
				type.name = "UFloat";
			case "vec2":
				type.name = "UVec2";
			case "vec3":
				type.name = "UVec3";
			case "vec4":
				type.name = "UVec4";
			default:
				throw "Unknown uniform type: " + uniform.type;
		}
		var f = {
				name : uniform.name, 
				doc : null, 
				meta : [], 
				access : [APublic], 
				kind : FVar(TPath(type), null), 
				pos : position 
			};
		fields.push(f);
		uniformFields.push( 
			{index:#if !js -1 #else null #end, fieldName: f.name, typeName:pack.join(".") + "." + type.name, extrainfo:extrainfo } 
		);
	}
	
	static function pragmas(src:String):String {
		var lines = src.split("\n");
		var found:Bool = true;
		for (i in 0...lines.length) {
			var l = lines[i];
			if (l.indexOf("#pragma include") > -1) {
				var info = l.substring(l.indexOf('"') + 1, l.lastIndexOf('"'));
				lines[i] = pragmas(sys.io.File.getContent(info));
			}
		}
		return lines.join("\n");
	}

	static function buildOverrides(fields:Array<Field>){		
		var func = {
			name : "createProperties", 
			doc : null, 
			meta : [], 
			access : [AOverride, APrivate], 
			kind : FFun( { args:[], params:[], ret:null, expr:macro { super.createProperties(); }} ),
			pos : Context.currentPos() 
		};
		fields.push(func);
	}
	
	static function buildFieldInitializers(allFields:Array<Field>){
		for (f in allFields) {
			switch(f.name) {
				case "createProperties":
					switch(f.kind) {
						case FFun(func):
							switch(func.expr.expr) {
								case EBlock(exprs):
									//Populate our variables
									//Create an array of uniforms
									
									for (uni in uniformFields) {
										var name:String = uni.fieldName;
										if (uni.typeName.split(".").pop() == "UTexture"){
											exprs.push(
												macro {
													var instance = Type.createInstance( Type.resolveClass( $v { uni.typeName } ), [$v { uni.fieldName }, $v { uni.index }, $v { uni.extrainfo } ]);
													Reflect.setField(this, $v { name }, instance);
													_uniforms.push(instance);
												}
											);
										}else {
											exprs.push(
												macro {
													var instance = Type.createInstance( Type.resolveClass( $v { uni.typeName } ), [$v { uni.fieldName}, $v { uni.index } ]);
													Reflect.setField(this, $v { name }, instance);
													_uniforms.push(instance);
												}
											);
										}
									}
									var stride:Int = 0;
									for (att in attributeFields) {
										var name:String = att.fieldName;
										var numItems:Int = att.itemCount;
										stride += numItems * 4;
										exprs.push(
											macro {
												var instance = Type.createInstance( Type.resolveClass( $v { att.typeName } ), [$v { att.fieldName }, $v { att.index }, $v { numItems } ]);
												Reflect.setField(this, $v { name }, instance);
												_attributes.push(instance);
											}
										);
									}
									exprs.push(
										macro {
											_aStride += $v { stride };
										}
									);
								default:
							}
						default:
					}
			}
		}
		
		uniformFields = null;
		attributeFields = null;
		return allFields;
	}

	//Macro Tools
	static function getClassField(name:String):ClassField{
		var type:ClassType = Context.getLocalClass().get();
		while(type != null){
			for(f in type.fields.get())
				if(f.name == name) return f;
			//try superclass
			type = type.superClass != null ? type.superClass.t.get() : null;
		}
		return null;
	}
	
	static function checkIfFieldDefined(name:String):Bool {
		return getClassField(name) != null;
	}

	public static function getFileContent( fileName : Expr ) {
        var fileStr = null;
        switch( fileName.expr ) {
        	case EConst(c):
            	switch( c ) {
            		case CString(s): fileStr = s;
            		default:
            	}
        	default:
        };
        if( fileStr == null ) Context.error("Constant string expected", fileName.pos);
        return Context.makeExpr(sys.io.File.getContent(fileStr),fileName.pos);
    }

    static function getString(e:Expr):String {
    	switch( e.expr ) {
    		case EConst(c):
    			switch( c ) {
    				case CString(s): return s;
    				case _:
    			}
    		case EField(e, f):	
    		case _:
    	}
    	throw("No const");
    }

    //GLSLSourceTools
    //:TODO: doesn't currently exclude non-global scope which might be an issue for complex shaders with many consts embedded
    static function extractGLSLGlobals(src:String, ?storageQualifiers:Array<String>):Array<GLSLGlobal>{
    	if(storageQualifiers == null)
    		storageQualifiers = ['const', 'attribute', 'uniform', 'varying'];

    	if(src == null) return [];

    	var allowedTypes = new Map<String, Array<String>>();
    	allowedTypes['const']     = ['bool','int','float','vec2','vec3','vec4','bvec2','bvec3','bvec4','ivec2','ivec3','ivec4','mat2','mat3','mat4'];
    	allowedTypes['attribute'] = ['float','vec2','vec3','vec4','mat2','mat3','mat4'];
    	allowedTypes['uniform']   = ['bool','int','float','vec2','vec3','vec4','bvec2','bvec3','bvec4','ivec2','ivec3','ivec4','mat2','mat3','mat4','sampler2D','samplerCube'];
    	allowedTypes['varying']   = ['float','vec2','vec3','vec4','mat2','mat3','mat4'];

    	var str = stripComments(src);

    	var globals = new Array<GLSLGlobal>();

    	for (storageQualifier in storageQualifiers) {
    		var types = allowedTypes[storageQualifier];

    		//format: (precision)? (type) (name1 (= (value))?, name2 (= (value))?);
    		var reg = new EReg(storageQualifier+'\\s+((lowp|mediump|highp)\\s+)?('+types.join('|')+')\\s+([^;]+)', 'gm');//we must double escape characters in this format
    		
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

    static function GLSLGlobalToString(g:GLSLGlobal):String{
    	return	(g.storageQualifier != null ? g.storageQualifier : '')+' '+
    			(g.precision != null ? g.precision : '')+' '+
    			g.type+' '+
    			g.name+
    			(g.arraySize != null ? '['+g.arraySize+']' : '')+';';

    }

	static function unifyLineEndings(src:String):String {
		return StringTools.trim(src.split("\r").join("\n").split("\n\n").join("\n"));
	}

	static function stripComments(src:String):String {
		return (~/(?:\/\*(?:[\s\S]*?)\*\/)|(?:\/\/(?:.*)$)/igm).replace(src, '');//#1 = block comments, #2 = line comments
	}

 	static var mainReg = (~/(?:\s|^)(?:(lowp|mediump|highp)\s+)?(void)\s+([main]+)\s*\([^\)]*\)\s*\{/gm);
	static function hasMain(src:String):Bool{
		if(src == null)return false;
		var str = stripComments(src);
		return mainReg.match(str);
	}

	static function stripMain(src:String):String {
		if(src == null)return null;
		var str = src;
		var reg = mainReg;
        
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
	#end
}