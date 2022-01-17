module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = normal: Str Id ":" Type
  | computed: Str Id ":" Type "=" Expr
  | block: "{" Question* "}"
  | ifThenElse: "if" "(" Expr ")" "{" Question* "}" "else" "{" Question* "}"
  | ifThen: "if" "(" Expr ")" "{" Question* "}"
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = ref: Id \ "true" \ "false" // true/false are reserved keywords.
  | strLit: Str
  | boolLit: Bool
  | intLit: Int
  > bracket "(" Expr ")"
  > right not: "!" Expr
  > left Expr ("*" | "/") Expr
  > right Expr ("+" | "-") Expr
  > left Expr ("\>" | "\<" | "\>=" | "\<=") Expr
  > left Expr ("==" | "!=") Expr
  > left Expr ("&&" | "||") Expr
  ;

syntax Type
  = intType: "integer"
  | stringType: "string"
  | boolType: "boolean"
  ;  
  
lexical Str = [\"] [A-Za-z0-9_\ ?():]+ [\"];

lexical Int 
  = [0]
  | [0-9]+;

lexical Bool = "true" | "false";



