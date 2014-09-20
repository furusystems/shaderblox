package shaderblox.macro.parser;
import shaderblox.macro.parser.Tokens;
/**
 * ...
 * @author Andreas Rønning
 */
typedef FunctionArg = { name:String, type:GLSLType}
typedef FunctionSignature = { returnType:GLSLType, name:String, args:Array<FunctionArg> }
typedef FieldSignature = { type:GLSLType, name:String, defaultValue:Null<Dynamic>, attributes:Array<GLSLFieldAttrib> }
typedef ParseError = { line:Int, msg:String }
class GLSLBlock {
	public var sig:FunctionSignature;
	public var string:String;
	public var superBlock:Null<GLSLBlock>;
	public inline function new() { }
}
class GLSLField {
	public var sig:FieldSignature;
	public var string:String;
	public inline function new() { }
}
class ShaderInfo
{
	public var isValid(get,never):Bool;
	public var errors:Array<ParseError>;
	public var blocks:Array<GLSLBlock>;
	public var fields:Array<GLSLField>;
	public function new() 
	{
		blocks = [];
		fields = [];
		errors = [];
	}
	inline function get_isValid():Bool {
		return errors.length == 0;
	}
	public function union(other:ShaderInfo):Null<ShaderInfo> {
		return this;
	}
	public function toString():String 
	{
		return "[ShaderInfo isValid=" + isValid + " blocks=" + blocks + " fields=" + fields + "]";
	}
	
}