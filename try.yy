%{
	#include <stdio.h>
	#include <stdlib.h>
	int errorCode = 0;
	int num = 0;
	char IO = 'N';
        int neg = 0;
	int storeType = 0;
	int arith = 0;
	int eval = 0;
%}

%skeleton "lalr1.cc"
%require "3.0.4"
%defines
%define api.token.constructor
%define api.value.type variant
%define parse.error verbose
%locations


%code requires
{
	#include <list>
	#include <string>
	#include <functional>
	using namespace std;
	struct s
	{
		string output;
		list<string> id;
	};
}


%code
{
	#include "parser.tab.hh"
	#include <sstream>
	#include <map>
	#include <regex>
	#include <set>
	yy::parser::symbol_type yylex();
	map<string, int> symbols;
        string labels()
        {
                string r = "__temp__" + atoi(num);
                num++;
		return r;
        };	
	string storeLabel = "";
	string storeCenter = "";
	string storePrevious = "";
	string storeCombine = "";
	string storeCurrent = "";
	string storeNumber = "";
	string storeArgument = "";
	string storeCaller = "";
	string storeVar = "";
	string storeID = "";
	string storeArray = "";
	string storeIndex = "";
	string storeName = "";
	string storeValue = "";
	string storeCondition = "";
	string storeRelation = "";
}

%token END 0 "end of file";
%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY TRUE FALSE  
%token INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE RETURN
%token SEMICOLON COLON COMMA NUMBER IDENT
%right ASSIGN
%left OR
%left AND 
%right NOT
%left EQ NEQ LT GT LTE GTE
%left ADD SUB
%left MULT DIV MOD
%left L_SQUARE_BRACKET R_SQUARE_BRACKET
%left L_PAREN R_PAREN

%type <string> IDENT NUMBER CONTINUE
%type <string> functions function identifiers identifier statement statements expression expressions
%type <string> term var vars bool_exp relation_and_exp relation_exp comp
%type <s> declarations declaration

%%

%start program;

program: functions	{if(errorCode == 0) cout << $1 << endl;}
	 ;

functions: /* epsilon */		{$$ = "";}
	| function functions		{$$ = $1 + "\n" + $2;}
	;

function: FUNCTION identifier SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY 	                   {$$ = "func" + $2 + "\n";																	     $$ += $5.output;																	      	      int i = 0;																		       for(list<string>::iterator it = $5.id.begin(); it != $5.id.end(); it++)												{																					$$ += *it + ", $" + to_string(i) + "\n";															 i++;																			   }																				    $$ += $8.output;																	     	     $$ += $11;																		      	      $$ += "endfunc\n";} 
           ;

declarations: /*epsilon*/						{$$.output = ""; $$.id = list<string>();}
	      | declaration SEMICOLON declarations		        													 {$$.output = $1.output + $3.output;																   $$.id = $1.id;																		    for(list<string>::iterator it = $3.id.begin(); it != $3.id.end(); it++)											     {																					$$.id.push_back(*it);																	       }}	
              ; 

declaration: identifiers COLON INTEGER																	      {$$.output = ". " + $1 + "\n"; $$.id.push_back($1);}
	     | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER											{$$.output = ".[] " + $1 + ", " + $5 + "\n"; $$.id.push_back($1);}
             ;

identifiers: identifier					{$$ = $1;}
	| identifier COMMA identifiers		        {$$ = $1;}
	;

identifier: IDENT		{$$ = $1;}

statements: statement SEMICOLON         		{$$ = $1;}
            | statement SEMICOLON statements		{$$ = $1 + "\n" + $3;}
            ;

statement: var ASSIGN expression																	    {IO = 'A'; $$ += $1;																	      if(storeType == 5) 																	       {$$ += $3;																			 if(storeType == 1) $$ += "= " + storeID + ", "  + storeCombine + "\n";                                                                                           else if(storeType == 2) $$ += "= " + storeID + ", " + storeVar + "\n";                                                                                           else if(storeType == 3) $$ += "= " + storeID + ", " + storeNumber + "\n";                                                                                        else if(storeType == 4) $$ += "= " + storeID + ", " + storeCaller + "\n";}			 							            else if(storeType == 6) 																	     {$$ = $3;																			       if(storeType == 1) $$ += "[]= " + storeArray + ", " + storeIndex + ", " + storeCombine  + "\n";							            	else if(storeType == 2) $$ += "[]= " + storeArray + ", " + storeIndex + ", " + storeVar  + "\n";								 else if(storeType == 3) $$ += "[]= " + storeArray + ", " + storeIndex + ", " + storeNumber  + "\n";							      	  else if(storeType == 4) $$ += "[]= " + storeArray + ", " + storeIndex + ", " + storeCaller  + "\n";}} 
	| IF bool_exp THEN statements ENDIF																   {symbols.insert(pair<string, int>(labels(),num)); $$ = $2;													     $$ += "?:= __label__" + to_string(symbols.begin()->second) + ", "  + storeCondition  + "\n";								      eval = to_string(symbols.begin()->second);														       symbols.erase(symbols.begin()->first);															        symbols.insert(pair<string, int>(labels(),num)); 														 $$ += ":= " + "__label__" + to_string(symbols.begin()->second) + "\n";											  	  symbols.erase(symbols.begin()->first);															   $$ += ": __label__" + to_string(eval) + "\n";														    $$ += $4;} 
	| IF bool_exp THEN statements ELSE statements ENDIF														   {symbols.insert(pair<string, int>(labels(),num)); $$ = $2;                                                                                                        $$ += "?:= __label__" + to_string(symbols.begin()->second) + ", "  + storeCondition  + "\n";                                                                     eval = to_string(symbols.begin()->second);                                                                                                                       symbols.erase(symbols.begin()->first);                                                                                                                           symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += ":= " + "__label__" + to_string(symbols.begin()->second) + "\n";                                                                                           symbols.erase(symbols.begin()->first);                                                                                                                           $$ += ": __label__" + to_string(eval) + "\n";                                                                                                                    $$ += $4;																			     $$ += ": __label__" + to_string(num) + "\n";														      $$ += $6;}
	| WHILE bool_exp BEGINLOOP statements ENDLOOP															   {symbols.insert(pair<string, int>(labels(),num));														     $$ = ": __label__" + to_string(symbols.begin()->second) + "\n";												      $$ += $2 + "\n"; 																		       $$ += $4; 																			if($4 == storeLabel) 										 								 {																				     do																				      { 																				$$ += $2 + "\n" + $4;																		}																	     			 while($4 == storeLabel);																       }																				symbols.erase(symbols.begin()->first);}
	| DO BEGINLOOP statements ENDLOOP WHILE bool_exp 														   {symbols.insert(pair<string, int>(labels(),num));														     $$ = ": __label__" + to_string(symbols.begin()->second) + "\n";                                                                                                  $$ += $3;                                                                                                                                                        if($3 == storeLabel)                                                                                                                                             {                                                                                                                                                                   while($3 == storeLabel)                                                                                                                                          {                                                                                                                                                                 $$ += $6 + "\n" + $3;                                                                                                                                           }                                                                                                                                                             }																				      symbols.erase(symbols.begin()->first);}  
	| READ vars							{IO = 'I'; $$ = $2 + "\n";}
	| WRITE vars							{IO = 'O'; $$ = $2 + "\n";}
	| CONTINUE 																			   {symbols.insert(pair<string, int>(labels(),num));														     storeLabel = symbols.begin()->first;															      $1 = storeLabel;																		       $$ = $1;																		                symbols.erase(storeLabel);}
	| RETURN expression                                             												   {$$ = $2; $$ += "ret ";                                                                                                                                           if(storeType == 1) $$ += storeCombine + "\n";														      else if(storeType == 2) $$ += storeVar + "\n";                                                                                                    	       else if(storeType == 3) $$ += storeCenter + "\n";                                                                                                                else if(storeType == 4) $$ += storeCaller + "\n";}
        ;

expression: multiplicative_exp				{$$ = $1;}
	| expression ADD multiplicative_exp																   {$$ = $1; storeCurrent = storeCenter; $$ += $3; storePrevious = storeCurrent; storeCurrent = storeCenter; 							     symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += "+ " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + "\n";									       storeCombine = symbols.begin()->first;																storeArgument = symbols.begin()->first;																 storeType = 1;	arith = 1;													         			  symbols.erase(symbols.begin()->first);}
	| expression SUB multiplicative_exp																   {$$ = $1; storeCurrent = storeCenter; $$ += $3; storePrevious = storeCurrent; storeCurrent = storeCenter;                                                         symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += "- " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + "\n";    								       storeCombine = symbols.begin()->first;							                                                                        storeArgument = symbols.begin()->first;																 storeType = 1;	arith = 2;														 			  symbols.erase(symbols.begin()->first);}
        ;

multiplicative_exp: term				{$$ = $1;}
	| multiplicative_exp MULT term		        														   {$$ = $1; storeCurrent = storeCenter; $$ += $3; storePrevious = storeCurrent; storeCurrent = storeCenter;                                                         symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += "* " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + "\n";									       storeCombine = symbols.begin()->first;																storeArgument = symbols.begin()->first;																 storeType = 1; arith = 3;		                                                                                                 			  symbols.erase(symbols.begin()->first);}
	| multiplicative_exp DIV term		        														   {$$ = $1; storeCurrent = storeCenter; $$ += $3; storePrevious = storeCurrent; storeCurrent = storeCenter;                                                         symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += "/ " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + "\n";                                                                         storeCombine = symbols.begin()->first;                                                                                                                           storeArgument = symbols.begin()->first;																 storeType = 1;	arith = 4;														 			  symbols.erase(symbols.begin()->first);}
	| multiplicative_exp MOD term		        														   {$$ = $1; storeCurrent = storeCenter; $$ += $3; storePrevious = storeCurrent; storeCurrent = storeCenter;                                                         symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += "% " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + "\n";                                                                         storeCombine = symbols.begin()->first;																storeArgument = symbols.begin()->first;																 storeType = 1;	arith = 5;														 			  symbols.erase(symbols.begin()->first);}
        ;

term: SUB var								{neg = 1; storeType = 2; IO = 'N'; $$ = $2;}
	| SUB NUMBER																			   {symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ = ". " + symbols.begin()->first + "\n";                                                                                                                       $$ += "= " + symbols.begin()->first + ", -" + $2 + "\n";													       storeCenter = symbols.begin()->first;																storeArgument = symbols.begin()->first;																 storeNumber = symbols.begin()->first;																  storeType = 3;																		   storeValue = $2;																		    symbols.erase(symbols.begin()->first);}
	| SUB L_PAREN expression R_PAREN				{neg = 1; storeType = 1; $$ = $3;}
	| var								{storeType = 2; IO = 'N'; $$ = $1;}
	| NUMBER																			   {symbols.insert(pair<string, int>(labels(),num)); 														     $$ = ". " + symbols.begin()->first + "\n";															      $$ += "= " + symbols.begin()->first + ", " + $1 + "\n";													       storeCenter = symbols.begin()->first;																storeArgument = symbols.begin()->first;																 storeNumber = symbols.begin()->first;																  storeType = 3;																		   storeValue = $1;			 															    symbols.erase(symbols.begin()->first);}
	| L_PAREN expression R_PAREN					{storeType = 1; $$ = $2;}
	| identifier L_PAREN expressions R_PAREN															   {$$ = $3; $$ += "param " + storeArgument;															     symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += ". " + symbols.begin()->first + "\n";														       $$ += "call " + $1 + ", " + symbols.begin()->first;														storeCaller = symbols.begin()->first;																 storeType = 4;																 			  symbols.erase(symbols.begin()->first);}
	| identifier L_PAREN R_PAREN																	   {symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += ". " + symbols.begin()->first + "\n";                                                                                                                      $$ += "call " + $1 + ", " + symbols.begin()->first;                                                                                                              storeCaller = symbols.begin()->first;																storeType = 4;                                                                                                                            			 symbols.erase(symbols.begin()->first);}
        ;

expressions: expression					{$$ = $1;}
	| expression COMMA expressions			{$$ = $1 + "\n" + $3;}
        ;

vars: var				{$$ = $1;}
	| var COMMA vars		{$$ = $1 + "\n" + $3;}

var: identifier 																		      {if(IO == 'A')                                                                                                                                                    {storeID = $1; storeType = 5;}																	 else if(IO == 'I') $$ = ".< " + $1;								   		          					  else if(IO == 'O') $$ = ".> " + $1;																   else if(IO = 'N')                                                                                                                                                {if(storeType == 2)                                                                                                                                               {symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ = ". " + symbols.begin()->first + "\n";                                                                                                                       if(neg == 0 || neg == 1)                                                                                                                                         {if(neg == 0) $$ += "= " + symbols.begin()->first + ", " + $1;                                                                                                    else if(neg == 1) $$ += "= " + symbols.begin()->first + ", -" + $1;}                                                                                             storeCenter = symbols.begin()->first;                                                                                                                            storeArgument = symbols.begin()->first;                                                                                                                          storeVar = symbols.begin()->first;                                                                                                                               storeName = $1;                                                                                                                                                  symbols.erase(symbols.begin()->first;}}} 
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET													        {if(IO == 'A') 																			  {$$ = $3; storeType = 6;																	    storeArray = $1;																		     storeIndex = storeArgument;}															             else if(IO == 'I' || 'O') 																	      {$$ = $3; 																			if(IO == 'I') $$ += ".[]< " + $1 + ", ";															 else if(IO == 'O') $$ += ".[]> " + $1 + ", ";															  if(storeType == 1) $$ += storeCombine + "\n";                                                                                           			   else if(storeType == 2) $$ += storeVar + "\n";                               					                                            else if(storeType == 3) $$ += storeNumber + "\n";                                                                                        		             else if(storeType == 4) $$ += storeCaller + "\n";} 												             else if(IO = 'N')																		      {if(storeType == 2 || storeType == 3)                                                                                                                             {symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ = ". " + symbols.begin()->first + "\n";                                                                                                                       if(neg == 0 || neg == 1) 																	    {if(neg == 0) $$ += "=[] " + symbols.begin()->first + ", " + $1 + ", ";											      else if(neg == 1) $$ += "=[] " + symbols.begin()->first + ", -" + $1 + ", "; 										       if(storeType == 2) $$ += storeName + "\n";                                                                                                                       else if(storeType == 3) $$ += storeValue + "\n";}						   		                              		         storeCenter = symbols.begin()->first;                                                                                                                            storeArgument = symbols.begin()->first;                                                                                                                          storeVar = symbols.begin()->first;															            storeName = $1;					                                                                                                             symbols.erase(symbols.begin()->first;}}}
         ;

bool_exp: relation_and_exp			{$$ = $1;}
	| bool_exp OR relation_and_exp																	   {$$ = $1; storeCurrent = storeRelation; $$ += $3; storePrevious = storeCurrent; storeCurrent = storeRelation;                                                     symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += "|| " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + "\n";                                                                        storeCondition = symbols.begin()->first;                                                                                                                         storeRelation = symbols.begin()->first;                                                                                                                          storeType = 7; arith = 6;                                                                                                                                        symbols.erase(symbols.begin()->first);} 
        ;

relation_and_exp: relation_exp				{$$ = $1;}
	| relation_and_exp AND relation_exp																   {$$ = $1; storeCurrent = storeRelation; $$ += $3; storePrevious = storeCurrent; storeCurrent = storeRelation;                                                     symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += "&& " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + "\n";                                                                        storeCondition = symbols.begin()->first;                                                                                                                         storeRelation = symbols.begin()->first;                                                                                                                          storeType = 7; arith = 7;                                                                                                                                        symbols.erase(symbols.begin()->first);}
        ;

relation_exp: NOT expression comp expression	        														       {$$ = $2; storeCurrent = storeArgument;                                                                                                                           $$ += $4; storePrevious = storeCurrent; storeCurrent = storeArgument;												  $$ += $3;																			   symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += "! " + symbols.begin()->first + ", " + storeRelation + "\n";                                                                                               storeCondition = symbols.begin()->first;                                                                                                                         storeRelation = symbols.begin()->first;                                                                                                                          storeType = 7; arith = 8;                                                                                                                                        symbols.erase(symbols.begin()->first);} 
	| NOT TRUE					{$$ = $2;}
	| NOT FALSE					{$$ = $2;}
	| NOT L_PAREN bool_exp R_PAREN																	   {$$ = $2;																			     symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ += "! " + symbols.begin()->first + ", " + storeRelation + "\n";                                                                                               storeCondition = symbols.begin()->first;                                                                                                                         storeRelation = symbols.begin()->first;                                                                                                                          storeType = 7; arith = 8;                                                                                                                                        symbols.erase(symbols.begin()->first);}
	| expression comp expression																	   {$$ = $1; storeCurrent = storeArgument;															     $$ += $3; storePrevious = storeCurrent; storeCurrent = storeArgument;											      $$ += $2;}
	| TRUE						{$$ = $1;}
	| FALSE						{$$ = $1;}
	| L_PAREN bool_exp R_PAREN			{$$ = $2;}
        ;

comp: EQ																			       {symbols.insert(pair<string, int>(labels(),num));														 $$ = ". " + symbols.begin()->first + "\n";                                                                                                                       $$ += "== " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + ", " + "\n";                                                                 storeRelation = symbols.begin()->first;                                                                                                                          symbols.erase(symbols.begin()->first);}	
	| NEQ																				   {symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ = ". " + symbols.begin()->first + "\n";                                                                                                                       $$ += "!= " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + ", " + "\n";                                                                 storeRelation = symbols.begin()->first;                                                                                                                          symbols.erase(symbols.begin()->first);}
	| LT																				   {symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ = ". " + symbols.begin()->first + "\n";                                                                                                                       $$ += "< " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + ", " + "\n";                                                                  storeRelation = symbols.begin()->first;                                                                                                                          symbols.erase(symbols.begin()->first);}
	| GT 																				   {symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ = ". " + symbols.begin()->first + "\n";                                                                                                                       $$ += "> " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + ", " + "\n";                                                                  storeRelation = symbols.begin()->first;                                                                                                                          symbols.erase(symbols.begin()->first);}
	| LTE																				   {symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ = ". " + symbols.begin()->first + "\n";                                                                                                                       $$ += "<= " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + ", " + "\n";                                                                 storeRelation = symbols.begin()->first;                                                                                                                          symbols.erase(symbols.begin()->first);}
	| GTE																				   {symbols.insert(pair<string, int>(labels(),num));                                                                                                                 $$ = ". " + symbols.begin()->first + "\n";                                                                                                                       $$ += ">= " + symbols.begin()->first + ", " + storePrevious + ", " + storeCurrent + ", " + "\n";                                                                 storeRelation = symbols.begin()->first;                                                                                                                          symbols.erase(symbols.begin()->first);}
        ;

%%

int main(int argc, char *argv[])
{
	yy::parser p;
	return p.parse();
}

void yy::parser::error(const yy::location& l, const std::string& m)
{
	std::cerr << l << ": " << m << std::endl;
}
