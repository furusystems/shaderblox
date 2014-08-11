package shaderblox.macro;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.Ref;
import haxe.rtti.Meta;
using Lambda;

/**
 * ...
 * @author Andreas Rønning
 */
private typedef FieldDef = {index:Null<Int>, typeName:String, fieldName:String, extrainfo:Dynamic };
private typedef AttribDef = {index:Int, typeName:String, fieldName:String, itemCount:Int };
private typedef GLSLGlobal = {storageQualifier:String, ?precision:String, type:String, name:String, ?arraySize:Int};
class ShaderBuilder
{
	#if macro
	
	static var uniformFields:Array<FieldDef>;
	static var attributeFields:Array<AttribDef>;
	static var vertSource:String;
	static var fragSource:String;
	static var asTemplate:Bool;
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
		asTemplate = false;
		for (f in type.meta.get().array()) {
			if (f.name == ":shaderNoBuild") return null;
			if (f.name == ":shaderTemplate") {
				asTemplate = true;
			}
		}
		
		uniformFields = [];
		attributeFields = [];
		var position = haxe.macro.Context.currentPos();
		var fields = Context.getBuildFields();
		var newFields:Array<Field> = [];
		var sources:Array<Array<String>> = [];
		var t2 = type;
		vertSource = "";
		fragSource = "";
		
		#if debug
		trace("Building " + Context.getLocalClass());
		#end
		
		
		while (t2.superClass != null) {
			t2 = t2.superClass.t.get();
			if (t2.superClass != null) {
				#if debug
				trace("\tIncluding: " + t2.name);
				#end
				sources.unshift(getSources(t2));
			}
		}
		sources.push(getSources(Context.getLocalClass().get()));
		for (i in sources) {
			if (i[0] != null) vertSource += i[0] + "\n";
			if (i[1] != null) fragSource += i[1] + "\n";
		}
		
		if(vertSource!=""){
			buildUniforms(position, newFields, vertSource);
			buildAttributes(position, newFields, vertSource);
		}else {
			throw "No vert source";
		}
		if(fragSource!=""){
			buildUniforms(position, newFields, fragSource);
		}else {
			throw "No frag source";
		}
		
		buildOverrides(fields);
		
		return complete(newFields.concat(fields));
	}
	
	static function buildAttributes(position, fields:Array<Field>, src:String) {
		var attributeTypes = ['float','vec2','vec3','vec4','mat2','mat3','mat4'];
		var attributes = extractGLSLGlobals(src, 'attribute', attributeTypes);
		for(a in attributes)
			buildAttribute(position, fields, a);
	}


	static function buildUniforms(position, fields:Array<Field>, src:String) {
		var uniformTypes = ['bool','int','float','vec2','vec3','vec4','bvec2','bvec3','bvec4','ivec2','ivec3','ivec4','mat2','mat3','mat4','sampler2D','samplerCube'];
		var uniforms = extractGLSLGlobals(src, 'uniform', uniformTypes);
		for(u in uniforms)
			buildUniform(position, fields, u);
	}

	static function extractGLSLGlobals(src:String, storageQualifier:String, types:Array<String>){
		var str = stripComments(src);

		var precisionQualifiers = ['lowp', 'mediump', 'highp'];

		var reg = new EReg(storageQualifier+'\\s+(('+precisionQualifiers.join('|')+')\\s+)?('+types.join('|')+')\\s+([^;]+)', 'gm');//we must double escape characters in this format

		var globals = new Array<GLSLGlobal>();

		while(reg.match(str)){
	        var precision = reg.matched(2);
	        var type = reg.matched(3);
	        var rawNamesStr = reg.matched(4);

	        //Extract comma separated names and array sizes (ie name[size])
	        var rName = ~/^\s*([\w\d_]+)(\[(\d*)\])?\s*$/igm;
	        for(rawName in rawNamesStr.split(',')){
				if(!rName.match(rawName)) continue;//name does not conform

	           	var global = {
	           		storageQualifier: storageQualifier,
	           		precision: precision,
	           		type: type,
	           		name: rName.matched(1),
	           		arraySize: Std.parseInt(rName.matched(3))
	           	};

	            globals.push(global);
	        }

	        str = reg.matchedRight();
	    }

	    return globals;
	}
	
	static function checkIfFieldDefined(name:String):Bool {
		var type:ClassType = Context.getLocalClass().get();
		while (type != null) {
			for (fld in type.fields.get()) {
				if (fld.name == name) {
					return true;
				}
			}
			if (type.superClass != null) {
				type = type.superClass.t.get();
			}else {
				type = null;
			}
		}
		return false;
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
	
	static function unifyLineEndings(src:String):String {
		return StringTools.trim(src.split("\r").join("\n").split("\n\n").join("\n"));
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

	static function stripComments(src:String):String {
		return (~/(?:\/\*(?:[\s\S]*?)\*\/)|(?:\/\/(?:.*)$)/igm).replace(src, '');//#1 = block comments, #2 = line comments
	}
	
	static function buildOverrides(fields:Array<Field>) 
	{
		var expression = macro {
			initFromSource($v { vertSource }, $v { fragSource } );
			ready = true;
		}
		var func = {
			name : "create", 
			doc : null, 
			meta : [], 
			access : [AOverride, APublic], 
			kind : FFun({args:[], params:[], ret:null, expr:expression}),
			pos : Context.currentPos() 
		};
		fields.push(func);
		
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
	
	static function complete(allFields:Array<Field>) 
	{
		var constructorFound:Bool = false;
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
													uniforms.push(instance);
												}
											);
										}else {
											exprs.push(
												macro {
													var instance = Type.createInstance( Type.resolveClass( $v { uni.typeName } ), [$v { uni.fieldName}, $v { uni.index } ]);
													Reflect.setField(this, $v { name }, instance);
													uniforms.push(instance);
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
												attributes.push(instance);
											}
										);
									}
									exprs.push(
										macro {
											aStride += $v { stride };
											//Reflect.setField(this, "aStride", $v{stride});
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
	#end
}