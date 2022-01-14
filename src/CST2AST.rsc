module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("", [], src=f@\loc); 
}

AQuestion cst2ast(Question q) {
  switch (q) {
  	case qst:(Question)`<Str s> <Id x> : <Type t>`: return normal("<s>", id("<x>", src=x@\loc), cst2ast(t), src=qst@\loc);
  	case qst:(Question)`<Str s> <Id x> : <Type t> = <Expr e>`: return comp("<s>", id("<x>", src=x@\loc), cst2ast(t), cst2ast(e), src=qst@\loc);
  	case qst:(Question)`{ <Question* qs> }`: return block([ cst2ast(qu) | Question qu <- qs ], src=qst@\loc);
  	case qst:(Question)`if ( <Id x> ) <Question qu> else <Question qu1>`: return ifThenElse(id("<x>", src=x@\loc), cst2ast(qu), cst2ast(qu1), src=qst@\loc);
  	case qst:(Question)`if ( <Id x> ) <Question qu>`: return ifThen(id("<x>", src=x@\loc), cst2ast(qu), src=qst@\loc);
  	default: throw "Unhandled question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case expr:(Expr)`<Id x>`: return ref(id("<x>", src=x@\loc), src=expr@\loc);
    case expr:(Expr)`<Str x>`: return strLit(stri("<x>", src=x@\loc), src=expr@\loc);
    case expr:(Expr)`<Bool x>`: return boolLit("<x>", src=expr@\loc);
    case expr:(Expr)`<Int x>`: return intLit("<x>", src=expr@\loc);
    case expr:(Expr)`! <Expr x>`: return not(cst2ast(x), src=expr@\loc);
    case (Expr)`( <Expr x> )`: return cst2ast(x);
    case expr:(Expr)`<Expr x> * <Expr y>`: return multi(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> / <Expr y>`: return div(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> + <Expr y>`: return add(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> - <Expr y>`: return sub(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> \> <Expr y>`: return gr(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> \< <Expr y>`: return less(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> \<= <Expr y>`: return leq(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> \>= <Expr y>`: return geq(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> == <Expr y>`: return eq(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> != <Expr y>`: return neq(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> && <Expr y>`: return and(cst2ast(x),cst2ast(y), src=expr@\loc);
    case expr:(Expr)`<Expr x> || <Expr y>`: return or(cst2ast(x),cst2ast(y), src=expr@\loc);
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
	switch (t) {
		case (Type)`string`: return string("string");
		case (Type)`boolean`: return boolean("boolean");
		case (Type)`integer`: return integer("integer");
		default: throw "Not yet implemented";
	}
}
