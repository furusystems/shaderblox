package shaderblox.macro.parser;

/**
 * ...
 * @author Andreas Rønning
 */

enum GLSLType {
	TFloat;
	TInt;
	TBool;
	TMatrix;
	TVec2;
	TVec3;
	TVec4;
	TVoid;
	TFunc(src:String);
}
enum GLSLDeclToken {
	Pragma;
	Uniform;
	Varying;
	Attribute;
	Ident(str:String);
	FType(t:GLSLType);
}