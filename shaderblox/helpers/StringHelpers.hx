package shaderblox.helpers;

/**
 * ...
 * @author Andreas Rønning
 */
using StringTools;
class StringHelpers
{
	static public inline function unifyLineEndings(src:String):String {
		return StringTools.trim(src.replace("\r", "\n").replace("\n\n","\n"));
	}
	static public inline function toLines(src:String):Array<String> {
		return unifyLineEndings(src).split("\n");
	}
	static public inline function trimSemis(src:String):String {
		return src.replace(";", "");
	}
	static public inline function trimParens(src:String):String {
		return src.replace(")", "").replace("(", "");
	}
	static public inline function cleanWhitespace(src:String):String {
		while (src.indexOf("  ") > -1) {
			src = src.replace("  ", " ");
		}
		return src;
	}
	static public inline function trimBraces(src:String):String {
		return src.replace("}", "").replace("{", "");
	}
	static public inline function flatten(src:String):String {
		return src.replace("\n", "");
	}
	
}