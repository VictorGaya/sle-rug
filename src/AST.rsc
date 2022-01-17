module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = normal(str label, AId identifier, AType \type)
  | comp(str label, AId identifier, AType \type, AExpr expr)
  | block(list[AQuestion] questions)
  | ifThenElse(AExpr guard, list[AQuestion] thenQs, list[AQuestion] elseQs)
  | ifThen(AExpr guard, list[AQuestion] thenQs)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | strLit(str name)
  | boolLit(bool b)
  | intLit(int i)
  | not(AExpr expr)
  | multi(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | add(AExpr lhs, AExpr rhs)
  | sub(AExpr lhs, AExpr rhs)
  | gr(AExpr lhs, AExpr rhs)
  | less(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | eq(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = intType()
  | strType()
  | boolType()
  ;
