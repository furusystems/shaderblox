package shaderblox.macro.parser;
import shaderblox.macro.parser.ShaderInfo.ParseError;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
using shaderblox.helpers.StringHelpers;
using StringTools;
using Std;

/**
 * ...
 * @author Andreas Rønning
 */
enum ShaderType {
	VERT;
	FRAG;
	TESC;
	TESE;
	COMP;
	GEOM;
}
typedef GLSLValidationError = { line:Int, char:Int, type:String, msg:String }
class Validator
{
	public static var VALIDATOR_PATH:String = "validator.exe";
	static public function validateLink(vertSrc:String, fragSrc:String):Array<GLSLValidationError> {
		return [];
	}
	static public function validateShader(src:String, ?type:ShaderType):Array<GLSLValidationError> 
	{
		if (VALIDATOR_PATH == "") return [];
		if (type == null) type = VERT;
		if (src.length == 0 || src == null) throw "No shader source";
		
		//create a temp file and dump our shader source to it
		var fileName = "validation_temp." + type.getName().toLowerCase();
		File.saveContent(fileName, src);
		
		//Run it through the validator and store the result
		var p = new Process(VALIDATOR_PATH, [fileName]);
		var data = p.stdout.readAll().toString();
		
		//Cleanup and return
		p.close();
		FileSystem.deleteFile(fileName);
		var errors = parseErrors(data);
		return errors;
	}
	
	static function parseErrors(str:String):Array<GLSLValidationError> 
	{
		if (str.length == 0) return [];
		var out = [];
		var lines = str.unifyLineEndings().split("\n");
		if (lines.length > 0) {
			lines.pop();
		}
		for (l in lines) {
			l = l.replace("ERROR: ", "");
			var buf = "";
			var idx = -1;
			var lineIdx = -1;
			var charIdx = -1;
			var tokenIdx = -1;
			var infoString = "";
			var typeString = "";
			while (idx < l.length) {
				idx++;
				var char = l.charAt(idx);
				if (char == ":" || idx == l.length) {
					buf = buf.trim();
					switch(++tokenIdx) {
						case 0:
							lineIdx = buf.parseInt();
						case 1:
							charIdx = buf.parseInt();
						case 2:
							typeString = buf;
						case 3:
							infoString = buf;
						default:
					}
					buf = "";
					continue;
				}
				buf += char;
			}
			out.push( { line:lineIdx, char:charIdx, type:typeString, msg:infoString } );
		}
		return out;
	}
	
}