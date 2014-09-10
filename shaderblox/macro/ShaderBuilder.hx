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
private typedef FieldDef = {index:Int, typeName:String, fieldName:String, extrainfo:Dynamic };
private typedef AttribDef = {index:Int, typeName:String, fieldName:String, itemCount:Int };
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
		
		//static fields
		
		var ct = TPath( { pack:type.pack, name:type.name } );
		
		var f = {
			name:"instance",
			kind:FVar(ct),
			access:[APublic, AStatic],
			pos:position
		}
		fields.push(f);
		
		//
		
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
			vertSource = pragmas(unifyLineEndings(vertSource));
			var lines:Array<String> = vertSource.split("\n");
			buildUniforms(position, newFields, lines);
			buildAttributes(position, newFields, lines);
			vertSource = lines.join("\n");
		}else {
			throw "No vert source";
		}
		if(fragSource!=""){
			fragSource = pragmas(unifyLineEndings(fragSource));
			var lines:Array<String> = fragSource.split("\n");
			buildUniforms(position, newFields, lines);
			fragSource = lines.join("\n");
		}else {
			throw "No frag source";
		}
		
		buildOverrides(fields);
		
		return complete(newFields.concat(fields));
	}

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
				case ":frag":
					foundFrag = true; 
					str = getString(i.params[0]);
					str = pragmas(unifyLineEndings(str));
					out[1] = str;
			}
		}
		return out;
	}
	
	
	
	static function buildAttributes(position, fields:Array<Field>, lines:Array<String>) {
		for (l in lines) {
			if (l.indexOf("attribute") > -1) {
				buildAttribute(position, fields, l);
			}
		}
	}
	static function buildUniforms(position, fields:Array<Field>, lines:Array<String>) {
		for (i in 0...lines.length) {
			var l = lines[i];
			if (l.indexOf("uniform") > -1) {
				l = buildUniform(position, fields, l);
			}
			lines[i] = l;
		}
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
	
	static function buildAttribute(position, fields, source:String):Void {
		source = StringTools.trim(source);
		var args = source.split(" ").slice(1);
		var name = StringTools.trim(args[1].split(";").join(""));
		
		//Avoid field redefinitions
		if (checkIfFieldDefined(name)) return;
		
		for (existing in attributeFields) {
			if (existing.fieldName == name) return; 
		}
		var pack = ["shaderblox", "attributes"];
		var itemCount:Int = 0;
		var itemType:Int = -1;
		switch(args[0]) {
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
				throw "Unknown attribute type: " + args[0];
		}
		var attribClassName:String = switch(itemType) {
			case GL_FLOAT:
				"FloatAttribute";
			default:
				throw "Unknown attribute type: " + itemType;
		}
		var type = { pack : pack, name : attribClassName, params : [], sub : null };
		var fld = {
				name : name, 
				doc : null, 
				meta : [], 
				access : [APublic], 
				kind : FVar(TPath(type), null), 
				pos : position 
			};
		fields.push(fld);
		var f = { index:attributeFields.length, fieldName:name, typeName:pack.join(".") + "." + attribClassName, itemCount:itemCount };
		attributeFields.push(f);
	}
	static function buildUniform(position, fields, source:String):String {
		source = StringTools.trim(source);
		
		//check annotations
		var annotation:Null<String>;
		var ai = source.indexOf("@");
		if (ai > -1) {
			//annotation found, which?
			annotation = source.substr(ai, source.indexOf(" ", ai));
			source = { var s = source.split(" "); s.shift(); s.join(" "); };
			switch(annotation) {
				case "@color":
				default: throw "Unknown annotation: " + annotation;
			}
		}
		
		var args = source.split(" ").slice(1);
		var name = StringTools.trim(args[1].split(";").join(""));
		
		if (checkIfFieldDefined(name)) return source;
		
		for (existing in uniformFields) {
			if (existing.fieldName == name) return source; 
		}
		
		var pack = ["shaderblox", "uniforms"];
		var type = { pack : pack, name : "UMatrix", params : [], sub : null };
		var extrainfo:Dynamic = null;
		switch(args[0]) {
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
				if (annotation == "@color") {
					type.name = "UColor3";
				}else {
					type.name = "UVec3";
				}
			case "vec4":
				if (annotation == "@color") {
					type.name = "UColor4";
				}else {
					type.name = "UVec4";
				}
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
			{index:-1, fieldName:f.name, typeName:pack.join(".") + "." + type.name, extrainfo:extrainfo } 
		);
		return source;
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
										var i:Expr = null;
										if (uni.typeName.split(".").pop() == "UTexture") {
											i = instantiation(uni.typeName, [macro $v{uni.fieldName}, macro  $v{uni.index}, macro  $v{uni.extrainfo}]);
										}else {
											i = instantiation(uni.typeName, [macro $v{uni.fieldName}, macro  $v{uni.index}]);
										}
										exprs.push(
											macro {
												uniforms.push($i { name } = $ { i });
											}
										);
									}
									var stride:Int = 0;
									for (att in attributeFields) {
										var name:String = att.fieldName;
										var numItems:Int = att.itemCount;
										stride += numItems * 4;
										var i:Expr = instantiation(att.typeName, [macro $v{att.fieldName}, macro  $v{att.index}, macro  $v{numItems}]);
										exprs.push(
											macro {
												attributes.push($i { name } = $ { i });
											}
										);
									}
									exprs.push(
										macro {
											aStride += $v { stride };
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
	
	static function instantiation(name:String, ?args:Array<Expr>):Expr {
		if (args == null) args = [];
		var s = name.split(".");
		name = s.pop();
		return { expr:ENew( { name:name, pack:s }, args), pos:Context.currentPos() };
	}
	#end
}