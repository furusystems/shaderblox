package shaderblox.macro.parser;

/**
 * ...
 * @author Andreas Rønning
 */

enum GLSLFieldAttrib {
	Pragma;
	Uniform;
	Varying;
	Attribute;
}

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
	Attribute(a:GLSLFieldAttrib);
	Ident(str:String);
	FType(t:GLSLType);
}