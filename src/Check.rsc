module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv tenvs = {};
  visit(f) {
    case normal(str label, AId identifier, AType \type): tenvs += <identifier.src, identifier.name, label, getType(\type)>;
    case comp(str label, AId identifier, AType \type, AExpr _): tenvs += <identifier.src, identifier.name, label, getType(\type)>;
  }
  return tenvs; 
}

/*
  map the abstract AType to a Type
*/
Type getType(AType at) {
  switch(at) {
  	case intType(): return tint();
  	case boolType(): return tbool();
  	case strType(): return tstr();
  	default: return tunknown();
  }
}

set[Message] check(AForm f) {
  return check(f,collect(f),resolve(f).useDef);
}

/*
  check every type in the TypeEnvironment and keep track of:
    - duplicate labels
    - duplicate questions (+ different types/labels)
  deep match on questions in f and check those as well
*/
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  rel[str n, Type t] seenNameType = {};
  rel[str IdName, str label] seenIdLabel = {};
  set[str] seenLabel = {};
  
  for (<loc def, str name, str label, Type \type> <- tenv) {
  	if(name in seenNameType<0>) {
  	  if(<name, label> notin seenIdLabel){
  	    msgs += { warning("Duplicate question name but with different label", def) };
  	  }
  	  if(<name,\type> notin seenNameType) {
  	    msgs += { error("Duplicate question name but with different type", def) };
  	  }
  	} else {
  	  seenNameType += {<name,\type>};
  	  seenIdLabel += {<name, label>};
  	}
  	
  	if(label in seenLabel) {
  	  msgs += { warning("Duplicate label detected", def) };
  	} else {
  	  seenLabel += {label};
  	}
  }
  
  for (/AQuestion q := f) {
    msgs += check(q,tenv,useDef);
  }
  
  return msgs; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch(q) {
    case comp(str _, AId _, AType \type, AExpr expr): {
      set[Message] newMsgs = check(expr,tenv,useDef);
      if(newMsgs == {} && getType(\type) != typeOf(expr,tenv,useDef)) {
        msgs += { error("Type of computed question does not match expression type", q.src) };
      }
      msgs += newMsgs;
    }
    case ifThenElse(AExpr guard, list[AQuestion] _, list[AQuestion] _): {
      set[Message] newMsgs = check(guard,tenv,useDef);
      if(newMsgs == {} && typeOf(guard,tenv,useDef) != tbool()) {
        msgs += { error("ELSE:Guard is not of type boolean", q.src) };
      }
      msgs += newMsgs;
    }
    case ifThen(AExpr guard, list[AQuestion] _): {
      set[Message] newMsgs = check(guard,tenv,useDef);
      if(newMsgs == {} && typeOf(guard,tenv,useDef) != tbool()) {
        msgs += { error("IF: Guard is not of type boolean", q.src) };
      }
      msgs += newMsgs;
    }
  }
  return msgs; 
}

set[Message] getMessages(AExpr e, AExpr lhs, AExpr rhs, TEnv tenv, UseDef useDef, str name, Type \type) {
  set[Message] lhsMsgs = check(lhs,tenv,useDef);
  set[Message] rhsMsgs = check(rhs,tenv,useDef);
  if (lhsMsgs == {} && rhsMsgs == {}) {
  	lhsMsgs += { error(name + ": Invalid type(s)", e.src) | typeOf(lhs,tenv,useDef) != \type || typeOf(rhs,tenv,useDef) != \type };
  }
  return lhsMsgs + rhsMsgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    case not(AExpr expr): {
      set[Message] recMsgs = check(expr,tenv,useDef);
      if (recMsgs == {}) {
      	msgs += { error("not: Invalid type(s)", expr.src) | typeOf(expr,tenv,useDef) != tbool() };
      }
      msgs += recMsgs;
    }
    case multi(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"multi",tint());
    case div(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"div",tint());
    case add(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"add",tint());
    case sub(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"sub",tint());
    case gr(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"gr",tint());
    case less(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"less",tint());
    case leq(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"leq",tint());
    case geq(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"geq",tint());
    case eq(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"eq",tint());
    case neq(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"neq",tint());
    case and(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"and",tbool());
    case or(AExpr lhs, AExpr rhs):
      msgs += getMessages(e,lhs,rhs,tenv,useDef,"or",tbool());
  }
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):
      if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
        return t;
      }
    case strLit(str _): return tstr();
    case intLit(int _): return tint();
    case boolLit(bool _): return tbool();
    case not(AExpr _): return tbool();
    case multi(AExpr _, AExpr _): return tint();
    case div(AExpr _, AExpr _): return tint();
    case add(AExpr _, AExpr _): return tint();
    case sub(AExpr _, AExpr _): return tint();
    case gr(AExpr _, AExpr _): return tbool();
    case less(AExpr _, AExpr _): return tbool();
    case leq(AExpr _, AExpr _): return tbool();
    case geq(AExpr _, AExpr _): return tbool();
    case eq(AExpr _, AExpr _): return tbool();
    case neq(AExpr _, AExpr _): return tbool();
    case and(AExpr _, AExpr _): return tbool();
    case or(AExpr _, AExpr _): return tbool();
    default: return tunknown();
  }
  return tunknown();
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

