module CST2AST

import Syntax;
import AST;

import ParseTree;

import String;
import Boolean;

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
  return cst2ast(f); 
}

AForm cst2ast(f: (Form)`form <Id identifier> { <Question* qs> }`) {
  return form("<identifier>", [cst2ast(q) | Question q <- qs], src=f@\loc);
}

/*
  converts all questions to AQuestions using a switch statement to differentiate between question types
  each AQuestion is also uniquely identifiable by its source location
*/
AQuestion cst2ast(Question q) {
  switch (q) {
  	case qst:(Question)`<Str s> <Id x> : <Type t>`: return normal("<s>", id("<x>", src=x@\loc), cst2ast(t), src=qst@\loc);
  	case qst:(Question)`<Str s> <Id x> : <Type t> = <Expr e>`: return comp("<s>", id("<x>", src=x@\loc), cst2ast(t), cst2ast(e), src=qst@\loc);
  	case qst:(Question)`{ <Question* qs> }`: return block([cst2ast(qu) | Question qu <- qs], src=qst@\loc);
  	case qst:(Question)`if ( <Expr x> ) { <Question* qs0> } else { <Question* qs1> }`: return ifThenElse(cst2ast(x), [cst2ast(qu) | Question qu <- qs0], [cst2ast(qu) | Question qu <- qs1], src=qst@\loc);
  	case qst:(Question)`if ( <Expr x> ) { <Question* qs> }`: return ifThen(cst2ast(x), [cst2ast(qu) | Question qu <- qs], src=qst@\loc);
  	default: throw "Unhandled question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>", src=x@\loc), src=e@\loc);
    case (Expr)`<Str x>`: return strLit("<x>", src=e@\loc);
    case (Expr)`<Bool x>`: return boolLit(fromString("<x>"), src=e@\loc);
    case (Expr)`<Int x>`: return intLit(toInt("<x>"), src=e@\loc);
    case (Expr)`! <Expr x>`: return not(cst2ast(x), src=e@\loc);
    case (Expr)`( <Expr x> )`: return cst2ast(x);
    case (Expr)`<Expr x> * <Expr y>`: return multi(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> / <Expr y>`: return div(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> + <Expr y>`: return add(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> - <Expr y>`: return sub(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> \> <Expr y>`: return gr(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> \< <Expr y>`: return less(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> \<= <Expr y>`: return leq(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> \>= <Expr y>`: return geq(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> == <Expr y>`: return eq(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> != <Expr y>`: return neq(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> && <Expr y>`: return and(cst2ast(x),cst2ast(y), src=e@\loc);
    case (Expr)`<Expr x> || <Expr y>`: return or(cst2ast(x),cst2ast(y), src=e@\loc);
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
	switch (t) {
		case (Type)`string`: return strType(src=t@\loc);
		case (Type)`boolean`: return boolType(src=t@\loc);
		case (Type)`integer`: return intType(src=t@\loc);
		default: throw "Unhandled type: <t>";
	}
}
