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
  = normal: Str Id ":" Type              					// question
  | computed: Str Id ":" Type "=" Expr      					// computed question
  | block: "{" Question* "}" 			   					// block
  | ifThenElse: "if" "(" Id ")" Question "else" Question		// if-then-else
  | ifThen: "if" "(" Id ")"  Question						// if-then
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = ref: Id \ "true" \ "false" // true/false are reserved keywords.
  | strLit: [A-Za-z][A-Za-z0_9]*
  | boolLit: Bool
  | intLit: Int
  > bracket "(" Expr ")"
  > right not: "!" Expr
  > left multi: Expr "*" Expr
  | left div: Expr "/" Expr
  > right add: Expr "+" Expr
  | right sub: Expr "-" Expr
  > left gr: Expr "\>" Expr
  | left less: Expr "\<" Expr
  | left leq: Expr "\<=" Expr
  | left geq: Expr "\>=" Expr
  > left eq: Expr "==" Expr
  | left neq: Expr "!=" Expr
  > left and: Expr "&&" Expr
  | left or: Expr "||" Expr
  ;
  
syntax Type
  = string: "boolean" or "string" or "integer" 
  ;  
  
lexical Str = [ \"] >> [A-Za-z0-9_\ ]+ >> [ \"];

lexical Int = [0-9]+;

lexical Bool = [true | false];



