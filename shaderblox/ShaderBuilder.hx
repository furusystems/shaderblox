package shaderblox;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Type.ClassType;
import haxe.rtti.Meta;
using Lambda;

/**
 * ...
 * @author Andreas Rønning
 */
private typedef FieldDef = {index:Int, typeName:String, fieldName:String };
private typedef AttribDef = {index:Int, typeName:String, fieldName:String, numFloats:Int };
class ShaderBuilder
{
	#if macro
	
	static var uniformFields:Array<FieldDef>;
	static var attributeFields:Array<AttribDef>;
	static var vertSource:String;
	static var fragSource:String;
	static var asTemplate:Bool;

	static function getSources(type:ClassType):Array<String> {
		var meta = type.meta.get();
		var out = [];
		var foundVert:Bool, foundFrag:Bool;
		var str:String;
		for (i in meta.array()) {
			switch(i.name) {
				case ":vert":
					foundVert = true; 
					str = getString(i.params[0]);
					str = pragmas(unifyLineEndings(str));
					out[0] = str;
					//var expr = macro { $v { str }};
					//f.kind = FVar(t, expr);
					//var src:Array<String> = str.split("\n");
					//buildUniforms(position, newFields, src);
					//buildAttributes(position, newFields, src);
				case ":frag":
					foundFrag = true; 
					str = getString(i.params[0]);
					str = pragmas(unifyLineEndings(str));
					out[1] = str;
					//var expr = macro { $v { str }};
					//f.kind = FVar(t, expr);
					//var src:Array<String> = str.split("\n");
					//buildUniforms(position, newFields, src);
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
		
		trace("Building " + Context.getLocalClass());
		
		
		while (t2.superClass != null) {
			t2 = t2.superClass.t.get();
			if(t2.superClass!=null){
				trace("\tIncluding: " + t2.name);
				sources.push(getSources(t2));
			}
		}
		sources.push(getSources(Context.getLocalClass().get()));
		for (i in sources) {
			
			if (i[0] != null) vertSource += i[0] + "\n";
			if (i[1] != null) fragSource += i[1] + "\n";
		}
		
		if(vertSource!=""){
			vertSource = pragmas(unifyLineEndings(vertSource));
			//var expr = macro { $v { str }};
			//f.kind = FVar(t, expr);
			var lines:Array<String> = vertSource.split("\n");
			buildUniforms(position, newFields, lines);
			buildAttributes(position, newFields, lines);
		}else {
			throw "No vert source";
		}
		if(fragSource!=""){
			fragSource = pragmas(unifyLineEndings(fragSource));
			//var expr = macro { $v { str }};
			//f.kind = FVar(t, expr);
			var lines:Array<String> = fragSource.split("\n");
			buildUniforms(position, newFields, lines);
		}else {
			throw "No frag source";
		}
		
		buildOverrides(fields);
		
		return complete(newFields.concat(fields));
	}
	
	static function buildAttributes(position, fields:Array<Field>, lines:Array<String>) {
		for (l in lines) {
			if (l.indexOf("attribute") > -1) {
				buildAttribute(position, fields, l);
			}
		}
	}
	static function buildUniforms(position, fields:Array<Field>, lines:Array<String>) {
		for (l in lines) {
			if (l.indexOf("uniform") > -1) {
				buildUniform(position, fields, l);
			}
		}
	}
	static function buildAttribute(position, fields, source:String) {
		source = StringTools.trim(source);
		var args = source.split(" ").slice(1);
		var name = StringTools.trim(args[1].split(";").join(""));
		
		var superClass = Context.getLocalClass().get().superClass.t.get();
		for (fld in superClass.fields.get()) {
			if (fld.name == name) {
				return;
			}
		}
		
		for (existing in attributeFields) {
			if (existing.fieldName == name) return; 
		}
		var pack = ["croissant", "renderer", "uniforms"];
		var type = { pack : pack, name : "FloatAttribute", params : [], sub : null };
		var numFloats:Int = 0;
		switch(args[0]) {
			case "float":
				numFloats = 1;
			case "vec2":
				numFloats = 2;
			case "vec3":
				numFloats = 3;
			case "vec4":
				numFloats = 4;
			default:
				throw "Unknown attribute type: " + args[0];
		}
		var fld = {
				name : name, 
				doc : null, 
				meta : [], 
				access : [APublic], 
				kind : FVar(TPath(type), null), 
				pos : position 
			};
		fields.push(fld);
		var f = { index:attributeFields.length, fieldName:name, typeName:pack.join(".") + ".FloatAttribute", numFloats:numFloats };
		attributeFields.push(f);
	}
	static function buildUniform(position, fields, source:String) {
		source = StringTools.trim(source);
		var args = source.split(" ").slice(1);
		var name = StringTools.trim(args[1].split(";").join(""));
		
		var superClass = Context.getLocalClass().get().superClass.t.get();
		for (fld in superClass.fields.get()) {
			if (fld.name == name) {
				return;
			}
		}
		
		for (existing in uniformFields) {
			if (existing.fieldName == name) return; 
		}
		var pack = ["croissant", "renderer", "uniforms"];
		var type = { pack : pack, name : "UMatrix", params : [], sub : null };
		switch(args[0]) {
			case "sampler2D":
				type.name = "UTexture";
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
				throw "Unknown uniform type: " + args[0];
		}
		var f = {
				name : name, 
				doc : null, 
				meta : [], 
				access : [APublic], 
				kind : FVar(TPath(type), null), 
				pos : position 
			};
		fields.push(f);
		uniformFields.push( 
			{index:-1, fieldName:f.name, typeName:pack.join(".") + "." + type.name } 
		);
	}
	
	static function getString(e:Expr):String {
		//trace("String: " + e);
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
	}
	
	static function complete(allFields:Array<Field>) 
	{
		var constructorFound:Bool = false;
		for (f in allFields) {
			switch(f.name){
				case "new":
				constructorFound = true;
				switch(f.kind) {
					case FFun(func):
						switch(func.expr.expr) {
							case EBlock(exprs):
								//Populate our variables
								//Create an array of uniforms
								
								for (uni in uniformFields) {
									var name:String = uni.fieldName;
									exprs.push(
										macro {
											var instance = Type.createInstance( Type.resolveClass( $v { uni.typeName } ), [$v { uni.fieldName}, $v { uni.index } ]);
											Reflect.setField(this, $v { name }, instance);
											uniforms.push(instance);
										}
									);
								}
								var stride:Int = 0;
								for (att in attributeFields) {
									var name:String = att.fieldName;
									var numFloats:Int = att.numFloats;
									stride += numFloats * 4;
									exprs.push(
										macro {
											var instance = Type.createInstance( Type.resolveClass( $v { att.typeName } ), [$v { att.fieldName }, $v { att.index }, $v { numFloats } ]);
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
		
		
		if (!constructorFound) {
			var superCall = macro super();
			var constructor = {
				name : "new", 
				doc : null, 
				meta : [], 
				access : [APublic], 
				kind : FFun({args:[], params:[], ret:null, expr:{expr:EBlock([superCall]), pos:Context.currentPos()}}),
				pos : Context.currentPos() 
			};
			allFields.push(constructor);
			return complete(allFields);
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