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
  	'\<form\>
  	'<displayQ(f)>
  	'\</form\>
  	'\</body\>
  	'\</html\>
  ");
}

str displayQ(AForm f) {
  newStr = "";
  visit(f) {
    case normal(str label, AId identifier, AType \type): {
	  newStr += "  \<label\><label>\</label\>\<br\>\n";
	  newStr += "  \<input type=\"<type2HTMLType(\type)>\" id=<identifier.src>\<br\>\n";
	}
	case comp(str label, AId identifier, AType \type, AExpr e): {
	  newStr += "  \<label\><label>\</label\>\<br\>\n";
	  newStr += "  \<input disabled type=\"<type2HTMLType(\type)>\" id=<identifier.src>\<br\>\n";
	}
	case ifThenElse(AExpr guard, list[AQuestion] thenQs, list[AQuestion] elseQs): {
	  newStr += "";
	}
	case ifThen(AExpr guard, list[AQuestion] thenQs): {
	  newStr += "";
	}
  }
  return "";
}

str type2HTMLType(AType \type) {
  switch (\type) {
	case intType(): return "number";
  	case boolType(): return "checkbox";
  	case strType(): return "text";
  }
}

str form2js(AForm f) {
  return "";
}
