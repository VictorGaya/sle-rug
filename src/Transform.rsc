module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  f.questions = flattenQs(f.questions, boolLit(true));
  return f; 
}

list[AQuestion] flattenQs(list[AQuestion] qs, AExpr cond) {
  list[AQuestion] newQs = [];
  for (AQuestion q <- qs) {
    switch(q){
      case normal(str _, AId _, AType _): newQs += ifThen(cond, [q]);
      case comp(str _, AId _, AType _, AExpr _): newQs += ifThen(cond, [q]);
      case block(list[AQuestion] questions): newQs += flattenQs(questions, cond);
      case ifThenElse(AExpr guard, list[AQuestion] thenQs, list[AQuestion] elseQs): newQs += flattenQs(thenQs, and(cond, guard)) + flattenQs(elseQs, and(cond, not(guard)));
      case ifThen(AExpr guard, list[AQuestion] thenQs): newQs += flattenQs(thenQs, and(cond, guard));
    }
  }
  return newQs;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName) {
   RefGraph r = resolve(cst2ast(f));
   
   set[loc] toRename = {};
   
   if (useOrDef in r.defs<1>) {
     toRename += {useOrDef};
     toRename += {u| <loc u, useOrDef> <-r.useDef};
   } else if (useOrDef in r.uses<0>){
     if (<useOrDef, loc d> <- r.useDef) {
       toRename += {u| <loc u, d> <-r.useDef} + {d};
     }
   } else {
     return f;
   }
   
   return visit(f) {
     case Id x => [Id]newName
       when x@\loc in toRename
   }
 } 
 
 