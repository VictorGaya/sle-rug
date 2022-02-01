module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

Value getDefaultValue(AType \type) {
  switch(\type) {
    case intType():
      return vint(0);
    case boolType():
      return vbool(false);
    case strType():
      return vstr("");
    default:
      throw("AType unknown");
  }
}

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();
  visit(f) {
    case normal(str _, AId identifier, AType \type):
      venv += (identifier.name: getDefaultValue(\type));
    case comp(str _, AId identifier, AType \type, AExpr _):
      venv += (identifier.name: getDefaultValue(\type));
  }
  return venv;
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

/*
  Evaluates every quesiton q in f
*/
VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for (/AQuestion q <- f) {
    venv = eval(q,inp,venv);
  }
  return venv; 
}

/*
  Evaluates a single question (recursively for blocks)
*/
VEnv eval(AQuestion q, Input inp, VEnv venv) {
  switch(q) {
    case normal(str _, AId identifier, AType _): {
      if(identifier.name == inp.question) {
        venv[identifier.name] = inp.\value;
      }
    }
    case comp(str _, AId identifier, AType _, AExpr expr): {
      if(identifier.name == inp.question) {
        venv[identifier.name] = eval(expr,venv);
      }
    }
    case block(list[AQuestion] questions): {
      for(AQuestion qu <- questions) {
        venv = eval(qu,inp,venv);
      }
    }
    case ifThenElse(AExpr guard, list[AQuestion] thenQs, list[AQuestion] elseQs): {
      if(eval(guard,venv).b) {
      	for(AQuestion qu <- thenQs){
        	venv = eval(qu,inp,venv);
      	}
      } else {
        for(AQuestion qu <- elseQs){
        	venv = eval(qu,inp,venv);
      	}
      }
    }
    case ifThen(AExpr guard, list[AQuestion] thenQs): {
      if(eval(guard,venv).b) {
        for(AQuestion qu <- thenQs){
        	venv = eval(qu,inp,venv);
      	}
      }
    }
  }
  return venv; 
}

/*
  recursively evaluate every AExpr
*/
Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    case strLit(str name): return vstr(name);
    case boolLit(bool b): return vbool(b);
    case intLit(int i): return vint(i);
    case not(AExpr expr): return vbool(!eval(expr,venv).b);
    case multi(AExpr lhs, AExpr rhs): return vint(eval(lhs,venv).n * eval(rhs,venv).n);
    case div(AExpr lhs, AExpr rhs): return vint(eval(lhs,venv).n / eval(rhs,venv).n);
    case add(AExpr lhs, AExpr rhs): return vint(eval(lhs,venv).n + eval(rhs,venv).n);
    case sub(AExpr lhs, AExpr rhs): return vint(eval(lhs,venv).n - eval(rhs,venv).n);
    case gr(AExpr lhs, AExpr rhs): return vbool(eval(lhs,venv).n > eval(rhs,venv).n);
    case less(AExpr lhs, AExpr rhs): return vbool(eval(lhs,venv).n < eval(rhs,venv).n);
    case leq(AExpr lhs, AExpr rhs): return vbool(eval(lhs,venv).n <= eval(rhs,venv).n);
    case geq(AExpr lhs, AExpr rhs): return vbool(eval(lhs,venv).n >= eval(rhs,venv).n);
    case eq(AExpr lhs, AExpr rhs): return vbool(eval(lhs,venv).n == eval(rhs,venv).n);
    case neq(AExpr lhs, AExpr rhs): return vbool(eval(lhs,venv).n != eval(rhs,venv).n);
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs,venv).b && eval(rhs,venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs,venv).b || eval(rhs,venv).b);
    default: throw "Unsupported expression <e>";
  }
}