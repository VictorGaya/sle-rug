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
  	'\<!DOCTYPE html\>
  	'\<html\>
  	'\<head\>
  	'\</head\>
  	'\<body\>
  	'\<script src=\"<f.src[extension="js"].top>\"\>\<\\script\>
  	'\<p\><f.name>\</p\>\<br\>
  	'\<form\"\>
  	'<displayForm(f)>
  	'\</form\>
  	'\</body\>
  	'\</html\>
  '");
}

str displayForm(<str name, list[AQuestion] questions>){
	displayQs(questions);
}

str displayQs(list[AQuestion] qs) {
  
  newStr = "";
  for (AQuestion q <- qs) {
    switch (q) {
      case normal(str label, AId identifier, AType \type): {
	    newStr += "\<label\><label>\</label\>\<br\>
	    		  '\<input type=\"<type2HTMLType(\type)>\" id=<identifier.src>\<br\>\n";
	  }
	  case comp(str label, AId identifier, AType \type, AExpr e): {
	    newStr += "  \<label\><label>\</label\>\<br\>
	              '\<p\>\</p\>";
	  }
	  case ifThenElse(AExpr guard, list[AQuestion] thenQs, list[AQuestion] elseQs): {
	    newStr += "\<div id=<thenQs.src> display=\"none\"\>
	    		  '<displayQs(thenQs)>
	    		  '\</div\>
	    		  '\<div id=<elseQs.src> display=\"none\"\>
	    		  '<displayQs(thenQs)>
	    		  '\</div\>
	    		  '";
	  }
	  case ifThen(AExpr guard, list[AQuestion] thenQs): {
	    newStr += "\<div id=<thenQs.src> display=\"none\"\>
	    		  '<displayQs(thenQs)>
	    		  '\</div\>
	    		  '";
	  }
	}
  }
  return "";
}

str type2HTMLType(AType \type) {
  switch (\type) {
	case intType(): return "number";
  	case boolType(): return "checkbox";
  	case strType(): return "text";
  	default: return "";
  }
  return "";
}

str type2Val(AType \type) {
  switch (\type) {
	case intType(): return "valueAsNumber";
  	case boolType(): return "checked";
  	case strType(): return "text";
  	default: return "";
  }
  return "";
}

str evalForm(<str name, list[AQuestion] questions>){
  someStr = "
  			'<onChanges(questions)>
  			'
  			'function reCalcQs() {
  			'<setValues(questions)>
  			'} 
  			'";
  return someStr;
}

str setValues(list[AQuestion] qs) {
  for (AQuestion q <- qs) {
    switch (q) {
      case normal(str label, AId identifier, AType \type): {
	    someStr += "document.getElementById(<guard.src>).value = 
	    		   'document.getElementById(<guard.src>).<type2Val(\type)>;";
	  }
	  case comp(str label, AId identifier, AType \type, AExpr e): {
	    someStr += "document.getElementById(<guard.src>).onchange = reCalcQs();";
	  }
	  case ifThenElse(AExpr guard, list[AQuestion] thenQs, list[AQuestion] elseQs): {
	    someStr += evalQs(thenQs);
	    someStr += evalQs(elseQs);
	  }
	  case ifThen(AExpr guard, list[AQuestion] thenQs): {
	    someStr += evalQs(thenQs);
	  }
	}
  }
  return someStr;
}

str type2Def(AType \type) {
  switch(\type){
    case intType(): return "0";
    case boolType(): return "false";
    case strType(): return "";
    default: return "";
  }
}

str onChanges(list[AQuestion] qs) {
  someStr = "";
  for (AQuestion q <- qs) {
    switch (q) {
      case normal(str _, AId identifier, AType \type): {
	    someStr += "document.getElementById(<identifier.src>).onchange = {reCalcQs()};
	    		   'document.getElementById(<identifier.src>).value = <type2Def(\type)>\n";
	  }
	  case comp(str _, AId identifier, AType \type, AExpr _): {
	    someStr += "document.getElementById(<identifier.src>).onchange = {reCalcQs()};
	    		   'document.getElementById(<identifier.src>).value = <type2Def(\type)>\n";
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

str form2js(AForm f) {
  return evalForm(f);
}
