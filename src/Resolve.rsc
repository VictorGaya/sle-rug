module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

/*
  Gathers all uses from the AForm by deep matching all AExprs in f,
  and saving the identifier information form each expression
*/
Use uses(AForm f) {
  Use uses = {};
  for (/AExpr expr := f) {
    uses += {<identifier.src, identifier.name> | /AId identifier := expr};
  }
  return uses; 
}

/*
  Gathers all defs from the AForm by deep matching all normal and computed questions,
  and saving the identifier information for each question
*/
Def defs(AForm f) {
  Def defs = {};
  defs += {<identifier.name, identifier.src> | /normal(str _, AId identifier, AType _) := f};
  defs += {<identifier.name, identifier.src> | /comp(str _, AId identifier, AType _, AExpr _) := f};
  return defs;
}