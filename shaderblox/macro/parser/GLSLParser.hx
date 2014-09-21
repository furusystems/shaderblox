package shaderblox.macro.parser;
import shaderblox.macro.parser.ShaderInfo.FunctionArg;
import shaderblox.macro.parser.ShaderInfo.GLSLBlock;
import shaderblox.macro.parser.ShaderInfo.GLSLField;
import shaderblox.macro.parser.Tokens;
/**
 * ...
 * @author Andreas Rønning
 */
using shaderblox.helpers.StringHelpers;
using StringTools;
class GLSLParser
{
	static inline var P_OPEN = "(";
	static inline var P_CLOSE = ")";
	static inline var C_OPEN = "{";
	static inline var C_CLOSE = "}";
	static inline var SEMI = ";";
	static inline var SPC = " ";
	
	static var functionBodyEreg:EReg = ~/\w[\w\s]+[\w\s]*\([\w\s,]*\)\s*{[\s\w\s=;,\.\(\)\+\-\*\\\[\]]*}/;
	static var fieldEreg:EReg = ~/[\w+\s+]+\w+\s+\w+\s*/;
	static var functionDeclEreg:EReg = ~/\w+\s+\w+\(\s*[\w\s,]*\)/;
	static var functionArgEreg:EReg = ~/\(\s*[\w\s,]*\)/;
	
	static var strBuf:String = "";

	public static function read(str:String):Null<ShaderInfo> {
		var fields:Array<String> = [];
		var info = new ShaderInfo();
		info.source = str;
		while (fieldEreg.match(str)) {
			var match = fieldEreg.matched(0);
			info.fields.push(parseField(match));
			str = str.replace(match, "");
		}
		while (functionBodyEreg.match(str)) {
			var match = functionBodyEreg.matched(0);
			info.blocks.push(parseBlock(match));
			str = str.replace(match, "");
		}
		var errors:Array<String> = [];
		return info.isValid ? info : null;
	}
	
	static function applyTokenToBlock(block:GLSLBlock, token:GLSLDeclToken) {
		switch(token) {
			case Ident(str):
				block.sig.name = str;
			case FType(t):
				block.sig.returnType = t;
			default:
				
		}
	}
	static function applyTokenToField(field:GLSLField, token:GLSLDeclToken) {
		switch(token) {
			case Ident(str):
				field.sig.name = str;
			case FType(t):
				field.sig.type = t;
			case Attribute(a):
				field.sig.attributes.push(a);
			default:
				
		}
	}
	
	static function parseField(line:String):GLSLField {
		var chars = line.trim().split("");
		trace("Reading field: " + line);
		chars.reverse();
		strBuf = "";
		var field = new GLSLField();
		field.source = line;
		field.sig = { name:"", type:null, defaultValue:null, attributes:[] };
		var out = [];
		while (chars.length > 0) {
			var char = chars.pop();
			if (char == SPC) {
				applyTokenToField(field, token(strBuf));
				strBuf = "";
				continue;
			}
			strBuf += char;
		}
		applyTokenToField(field, token(strBuf));
		strBuf = "";
		return field;
	}
	
	static function parseFunctionArg(str:String):FunctionArg {
		str = str.trim();
		var splt = str.split(" ");
		return { name:splt[1], type:parseType(splt[0]) }; 
	}
	
	static private function parseType(str:String):GLSLType 
	{
		str = str.toLowerCase();
		switch(str) {
			case "float":
				return TFloat;
			case "void":
				return TVoid;
			case "int":
				return TInt;
			case "bool":
				return TBool;
			case "vec2":
				return TVec2;
			case "vec3":
				return TVec3;
			case "vec4":
				return TVec4;
			case "matrix":
				return TMatrix;
		}
		throw "Unknown argument type '"+str+"'";
	}
	
	static function parseBlock(src:String):GLSLBlock {
		functionDeclEreg.match(src);
		var decl = functionDeclEreg.matched(0);
		functionArgEreg.match(decl);
		var args = functionArgEreg.matched(0).trimParens().cleanWhitespace();
		//if(args==""||args.toLowerCase()=="void") //Something?
		var a = args.split(",");
		
		strBuf = "";
		var block = new GLSLBlock();
		block.source = src;
		block.sig = { name:"", returnType:null, args:[]};
		
		for (i in 0...a.length) {
			block.sig.args.push(parseFunctionArg(a[i]));
		}
		//strBuf = "";
		return block;
	}
	
	static function token(str:String):GLSLDeclToken {
		var tmp = StringTools.trim(str.trimSemis().toLowerCase());
		trace("Reading token from: " + str);
		switch(tmp) {
			case "attribute":
				return Attribute(Attribute);
			case "uniform":
				return Attribute(Uniform);
			case "varying":
				return Attribute(Varying);
			case "float":
				return FType(TFloat);
			case "void":
				return FType(TVoid);
			case "int":
				return FType(TInt);
			case "bool":
				return FType(TBool);
			case "vec2":
				return FType(TVec2);
			case "vec3":
				return FType(TVec3);
			case "vec4":
				return FType(TVec4);
			case "matrix":
				return FType(TMatrix);
			default:
				return Ident(str.trimSemis());
		}
	}
}