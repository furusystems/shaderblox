package shaderblox.macro.parser;
import shaderblox.macro.parser.Tokens;
/**
 * ...
 * @author Andreas Rønning
 */
using shaderblox.helpers.StringHelpers;
class GLSLParser
{
	static inline var C_OPEN = "{";
	static inline var C_CLOSE = "}";
	static inline var SEMI = ";";
	static inline var SPC = " ";
	
	public static function read(str:String):Null<ShaderInfo> {
		var lines = str.toLines();
		lines.reverse();
		var info = new ShaderInfo();
		var errors:Array<String> = [];
		while (lines.length > 0) readLine(lines, info);
		return info.isValid ? info : null;
	}
	static function readLine(lines:Array<String>, info:ShaderInfo) {
		var l = lines.pop();
		trace(parse(l));
	}
	static function token(str:String):GLSLDeclToken {
		var tmp = str.trimSemis().toLowerCase();
		switch(tmp) {
			case "attribute":
				return Attribute;
			case "uniform":
				return Uniform;
			case "varying":
				return Varying;
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
			default:
				return Ident(str.trimSemis());
		}
	}
	static function parse(line:String):Array<GLSLDeclToken> {
		var chars = line.split("");
		chars.reverse();
		var buffer:String = "";
		var out = [];
		while (chars.length > 0) {
			var char = chars.pop();
			if (char == SPC) {
				out.push(token(buffer));
				buffer = "";
				continue;
			}
			buffer += char;
		}
		return out;
	}
}