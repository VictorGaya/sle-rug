module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  return html("
  	'\<head\>
  	'\</head\>
  	'\<body\>
  	'\<script src=\"<f.src[extension="js"].top>\"\>\</script\>
  	'\<p\><f.name>\</p\>\<br\>
  	'\<form\>
  	'<displayQs(f.questions)>
  	'\</form\>
  	'\</body\>
  '");
}

str displayQs(list[AQuestion] qs) {
  
  str newStr = "";
  for (AQuestion q <- qs) {
    switch (q) {
      case normal(str label, AId identifier, AType \type): {
	    newStr += "\t\<label\><label>\</label\>\<br\>
	    		  '\t\<input type=\"<type2HTMLType(\type)>\" id=\"<identifier.name>\"\>\<br\>\n";
	  }
	  case comp(str label, AId identifier, AType _, AExpr _): {
	    newStr += "\t\<label\><label>\</label\>\<br\>
	              '\t\<p id=\"<identifier.name>\"\>\</p\>";
	  }
	  case ifThenElse(AExpr guard, list[AQuestion] thenQs, list[AQuestion] elseQs): {
	    newStr += "\t\<div id=\"IF-<guard.src>\" style=\"display: none\"\>
	    		  '\t<displayQs(thenQs)>
	    		  '\t\</div\>
	    		  '\t\<div id=\"ELSE-<guard.src>\" style=\"display: none\"\>
	    		  '\t<displayQs(elseQs)>
	    		  '\t\</div\>
	    		  '";
	  }
	  case ifThen(AExpr guard, list[AQuestion] thenQs): {
	    newStr += "\t\<div id=\"IF-<guard.src>\" style=\"display: none\"\>
	    		  '\t<displayQs(thenQs)>
	    		  '\t\</div\>
	    		  '";
	  }
	}
  }
  return newStr;
}

str type2HTMLType(AType \type) {
  switch (\type) {
	case intType(): return "number";
  	case boolType(): return "checkbox";
  	case strType(): return "text";
  	default: return "";
  }
}


str form2js(AForm f) {
  return "
  		 '<onChanges(f.questions)>
  		 '
  		 'function reCalcQs() {
  		 '<setValues(f.questions)>
  		 '} 
  		 '";
}

str onChanges(list[AQuestion] qs) {
  str someStr = "";
  for (AQuestion q <- qs) {
    switch (q) {
      case normal(str _, AId identifier, AType \type): {
	    someStr += "document.getElementById(\"<identifier.name>\").onchange = function(){reCalcQs()};
	    		   'document.getElementById(\"<identifier.name>\").value = <type2Def(\type)>;\n";
	  }
	  case comp(str _, AId identifier, AType \type, AExpr _): {
	    someStr += "document.getElementById(\"<identifier.name>\").onchange = function(){reCalcQs()};
	    		   'document.getElementById(\"<identifier.name>\").value = <type2Def(\type)>;\n";
	  }
	  case ifThenElse(AExpr _, list[AQuestion] thenQs, list[AQuestion] elseQs): {
	    someStr += onChanges(thenQs);
	    someStr += onChanges(elseQs);
	  }
	  case ifThen(AExpr _, list[AQuestion] thenQs): {
	    someStr += onChanges(thenQs);
	  }
	}
  }
  return someStr;
}

str setValues(list[AQuestion] qs) {
  str someStr = "";
  for (AQuestion q <- qs) {
    switch (q) {
      case normal(str _, AId identifier, AType \type): {
	    someStr += "\tdocument.getElementById(\"<identifier.name>\").value = document.getElementById(\"<identifier.name>\").<type2Val(\type)>;\n";
	  }
	  case comp(str _, AId identifier, AType \type, AExpr e): {
	    someStr += "\tdocument.getElementById(\"<identifier.name>\").innerHTML = <expr2Str(e, \type)>;";
	  }
	  case ifThenElse(AExpr guard, list[AQuestion] thenQs, list[AQuestion] elseQs): {
	    someStr += "if (<expr2Str(guard, boolType())>){
	    		   '\tdocument.getElementById(\"IF-<guard.src>\").style.display = \"\";
	    		   '\tdocument.getElementById(\"ELSE-<guard.src>\").style.display = \"none\";
	    		   '\t<setValues(thenQs)>
	    		   '} else {
	    		   '\tdocument.getElementById(\"IF-<guard.src>\").style.display = \"none\";
	    		   '\tdocument.getElementById(\"ELSE-<guard.src>\").style.display = \"\";
	    		   '\t<setValues(elseQs)>
	    		   '}\n"  ;
	  }
	  case ifThen(AExpr guard, list[AQuestion] thenQs): {
	    someStr += "\tdocument.getElementById(\"IF-<guard.src>\").style.display = <expr2Str(guard, boolType())>?\"\":\"none\";\n" + setValues(thenQs);
	  }
	  default: someStr += "<q>";
	}
  }
  return someStr;
}

str type2Val(AType \type) {
  switch (\type) {
	case intType(): return "valueAsNumber";
  	case boolType(): return "checked";
  	case strType(): return "innerHTML";
  	default: return "";
  }
}

str type2Def(AType \type) {
  switch(\type){
    case intType(): return "0";
    case boolType(): return "false";
    case strType(): return "";
    default: return "";
  }
}

str expr2Str(AExpr e, AType \type) {
  str someStr = "";
  switch (e) {
    case ref(id(str name)): someStr += "document.getElementById(\"<name>\").<type2Val(\type)>";
    case strLit(str name): someStr += name;
    case boolLit(bool b): someStr += "<b>";
    case intLit(int i): someStr += "<i>";
    case not(AExpr expr): someStr += "!(<expr2Str(expr, \type)>)";
    case multi(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, intType())>)*(<expr2Str(rhs, intType())>)";
    case div(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, intType())>)/(<expr2Str(rhs, intType())>)";
    case add(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, intType())>)+(<expr2Str(rhs, intType())>)";
    case sub(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, intType())>)-(<expr2Str(rhs, intType())>)";
    case gr(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, intType())>)\>(<expr2Str(rhs, intType())>)";
    case less(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, intType())>)\<(<expr2Str(rhs, intType())>)";
    case leq(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, intType())>)\<=(<expr2Str(rhs, intType())>)";
    case geq(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, intType())>)\>=(<expr2Str(rhs, intType())>)";
    case eq(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, intType())>)===(<expr2Str(rhs, intType())>)";
    case neq(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, intType())>)!==(<expr2Str(rhs, intType())>)";
    case and(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, boolType())>)&&(<expr2Str(rhs, boolType())>)";
    case or(AExpr lhs, AExpr rhs): someStr += "(<expr2Str(lhs, boolType())>)||(<expr2Str(rhs, boolType())>)";
    default: someStr += "";
  }
  return someStr;
}

