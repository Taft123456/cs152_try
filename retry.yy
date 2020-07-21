%{
  #include <stdio.h>
  #include <stdlib.h>
  int errorCode = 0;
  int num = 0;
  int arith = 0;
  int IDtype;
  int exp_type = 0;
  int before_assign;
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
	/* you may need these header files 
	 * add more header file if you need more
	 */
#include <list>
#include <string>
#include <functional>
using namespace std;
struct dec
{
   string output;
   list<string> id;
};
	/* define the sturctures using as types for non-terminals */
	/* end the structures for non-terminal types */
}


%code
{
#include "parser.tab.hh"

	/* you may need these header files 
	 * add more header file if you need more
	 */
#include <sstream>
#include <map>
#include <regex>
#include <set>
yy::parser::symbol_type yylex();
map<string, int> symbols;
string labels()
{
        string r = "__temp__" + itoa(num);
        num++;
        return r;
};
string getVar;
string getNum;
string getTerm;
string representIndex;
string LS;
string RS;
string label;
string temp;
string represent1;
string represent2;
string general_exp;
	/* define your symbol table, global variables,
	 * list of keywords or any function you may need here */
	/* end of your code */
}

%token END 0 "end of file";

	/* specify tokens, type of non-terminals and terminals here */
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
%type <dec> declarations declaration 
	/* end of token specifications */

%%

%start program;

	/* define your grammars here use the same grammars 
	 * you used in Phase 2 and modify their actions to generate codes
	 * assume that your grammars start with prog_start
	 */

program: functions	{if(errorCode == 0) cout << $1 << endl;}
	 ; 


functions: /* epsilon */		{$$ = "";}
	| function functions		{$$ = $1 + "\n" + $2;}
	;


function: FUNCTION identifier SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
	  {$$ = "func" + $2 + "\n";
	   $$ += $5.output;
	   int i = 0;
	   for(list<string>::iterator it = $5.id.begin(); it != $5.id.end(); it++)
	   {$$ += *it + ", $" + to_string(i) + "\n"; i++;}
	   $$ += $8.output;
	   $$ += $11;
	   $$ += "endfunc\n";} 


declarations: /*epsilon*/						{$$.output = ""; $$.id = list<string>();}
	| declaration SEMICOLON declarations		                
          {$$.output = $1.output + $3.output; 
           $$.id = $1.id;
           for(list<string>::iterator it = $3.id.begin(); it != $3.id.end(); it++)
           {$$.id.push_back(*it);}}	
        ;


declaration: identifiers COLON INTEGER								
             {$$.output = ". " + $1 + "\n"; 
	      $$.id.push_back($1);} 
	| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER		
          {$$.output = ".[] " + $1 + ", " + $5 + "\n"; 
	   $$.id.push_back($1);}
        ;

			
identifiers: identifier					{$$ = $1;}
	| identifier COMMA identifiers		        {$$ = $1 + $3;}
	;


identifier: IDENT		{$$ = $1;}
	;


statements: statement SEMICOLON         		{$$ = $1;}
        | statement SEMICOLON statements		{$$ = $1 + "\n" + $3;}
        ;


statement: var ASSIGN expression					
	   {before_assign = 0; 
	    $$ = $3;
	    if(IDtype == 0) 
            {before_assign = 1;
	     $$ += $1;
	     $$ += "= " + getVar + ", " + general_exp;}
	    else if(IDtype == 1)
	    {before_assign = 1;
	     $$ += $1;
	     $$ += "[]= " + getVar + ", " + representIndex + ", " + general_exp;}}   
	| IF bool_exp THEN statements ENDIF				{printf("statement -> IF bool_exp THEN statements ENDIF\n");}
	| IF bool_exp THEN statements ELSE statements ENDIF		{printf("statement -> IF bool_exp THEN statements ELSE statements ENDIF\n");}
	| WHILE bool_exp BEGINLOOP statements ENDLOOP			{printf("statement -> WHILE bool_exp BEGINLOOP statements ENDLOOP\n");}
	| DO BEGINLOOP statements ENDLOOP WHILE bool_exp 		{printf("statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_exp\n");}
	| READ vars							{printf("statement -> READ vars\n");}
	| WRITE vars							{printf("statement -> WRITE vars\n");}
	| CONTINUE 							{printf("statement -> CONTINUE\n");}
	| RETURN expression                                             {printf("statement -> RETURN expression\n");}
        ;


expression: multiplicative_exp					{exp_type = 1; $$ = $1;}
	| expression ADD multiplicative_exp		
	  {exp_type = 1;
	   $$ = $1;
	   represent2 = represent1;
	   LS = getTerm; 
	   $$ += $3;
	   RS = getTerm;
	   represent1 = label();
	   $$ += "+ " + represent1 + ", " + label + ", " + represent2 + "\n";
	   general_exp = represent1;
	   arith = 1;}
	| expression SUB multiplicative_exp		
	  {exp_type = 1;
	   $$ = $1;
	   represent2 = represent1;
	   $$ += $3;
           represent1 = label();
           $$ += "- " + represent1 + ", " + label + ", " + represent2 + "\n";
	   general_exp = represent1;
	   arith = 2;}
        ;


multiplicative_exp: term				{exp_type = 1; $$ = $1;}
	| multiplicative_exp MULT term		        
	  {exp_type = 1;
	   $$ = $1;
	   LS = getTerm;
	   $$ += $3;
	   RS = getTerm;
           represent1 = label();
           $$ += "* " + represent1 + ", " + temp + ", " + label + "\n";
	   general_exp = represent1;
	   arith = 3;}
	| multiplicative_exp DIV term		        
	  {exp_type = 1;
	   $$ = $1;
           LS = getTerm;
           $$ += $3;
           RS = getTerm;
           represent = label();
           $$ += "/ " + represent1 + ", " + temp + ", " + label + "\n";
	   general_exp = represent1;
	   arith = 4;} 
	| multiplicative_exp MOD term		        
	  {exp_type = 1;
	   $$ = $1;
           LS = getTerm;
           $$ += $3;
           RS = getTerm;
           represent = label();
           $$ += "% " + represent1 + ", " + temp + ", " + label + "\n";
	   general_exp = represent1;
	   arith = 5;}
        ;


term: SUB var								{printf("term -> SUB var\n");}
	| SUB NUMBER							{printf("term -> SUB NUMBER\n");}
	| SUB L_PAREN expression R_PAREN				{printf("term -> SUB L_PAREN expression R_PAREN\n");}
	| var								{$$ = $1;}
	| NUMBER							
          {exp_type = 2;
	   temp = label; 
           label = labels();
           $$ = ". " + label;
           $$ += "= " + label + ", " + $1;
	   general_exp = label;
	   getNum = $1;
	   getTerm = $1;}
	| L_PAREN expression R_PAREN					{$$ = $2;}
	| identifier L_PAREN expressions R_PAREN			{printf("term -> identifier L_PAREN expressions R_PAREN\n");}
	| identifier L_PAREN R_PAREN					{printf("term -> identifier L_PAREN R_PAREN\n");}
        ;


expressions: expression					{$$ = $1;}
	| expression COMMA expressions			{$$ = $1 + "\n" + $3;}
        ;


vars: var				{$$ = $1;}
	| var COMMA vars		{$$ = $1 + "\n" + $3;}
        ;
 

var: identifier									
     {exp_type = 3;
      if(before_assign == 0)
      {temp = label;
       label = labels();
       $$ = ". " + label;
       $$ += "= " + label + ", " + $1;
       symbols.insert(pair<string, int>("scaler",0));
       IDtype = symbols.begin()->second;
       symbols.erase("scaler");
       general_exp = label;}
      getVar = $1;
      getTerm = $1;}
	| identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET		
	  {$$ = $3;
	   if(before_assign == 0)
	   {temp = label;
	    label = labels();
	    symbols.insert(pair<string, int>("array",1));
            IDtype = symbols.begin()->second;
            symbols.erase("array");
            general_exp = label;}
	   if(exp_type == 1)
	   {if(before_assign == 0) {$$ += "=[] " + label + ", " + $1 + ", ";} 
	    switch(arith)
	    {case 1: 
		if(before_assign == 0) {$$ += LS + " + " + RS + "\n";}
		else if(before_assign == 1) {representIndex = LS + " + " + RS;}
		break; 
	     case 2: 
		if(before_assign == 0) {$$ += LS + " - " + RS + "\n";}
                else if(before_assign == 1) {representIndex = LS + " - " + RS;}
                break;
	     case 3: 
		if(before_assign == 0) {$$ += LS + " * " + RS + "\n";}
                else if(before_assign == 1) {representIndex = LS + " * " + RS;}
                break;
	     case 4: 
		if(before_assign == 0) {$$ += LS + " / " + RS + "\n";}
                else if(before_assign == 1) {representIndex = LS + " / " + RS;}
                break;
	     case 5: 
		if(before_assign == 0) {$$ += LS + " % " + RS + "\n";}
                else if(before_assign == 1) {representIndex = LS + " % " + RS;}
                break;}}
           else if(exp_type == 2) 
	   {if(before_assign == 0) {$$ += "=[] " + label + ", " + $1 + ", " + getNum + "\n";}
	    else if(before_assign == 1) {representIndex = getNum;}}
	   else if(exp_type == 3) 
	   {if(before_assign == 0) {$$ += "=[] " + label + ", " + $1 + ", " + getVar + "\n";}
	    else if(before_assign == 1) {representIndex = getVar;}}
	  getVar = $1;
          getTerm = $1;} 
        ;


bool_exp: relation_and_exp			{$$ = $1;}
	| bool_exp OR relation_and_exp		{printf("bool_exp -> relation_and_exp OR relation_and_exp\n");}
        ;


relation_and_exp: relation_exp				{$$ = $1;}
	| relation_and_exp AND relation_exp		{printf("relation_and_exp -> relation_exp AND relation_exp\n");}
        ;


relation_exp: NOT expression comp expression	        {printf("relation_exp -> NOT expression comp expression\n");}
	| NOT TRUE					{printf("relation_exp -> NOT TRUE\n");}
	| NOT FALSE					{printf("relation_exp -> NOT FALSE\n");}
	| NOT L_PAREN bool_exp R_PAREN			{printf("relation_exp -> NOT L_PAREN bool_exp R_PAREN\n");}
	| expression comp expression			{printf("relation_exp -> expression comp expression\n");}
	| TRUE						{printf("relation_exp -> TRUE\n");}
	| FALSE						{printf("relation_exp -> FALSE\n");}
	| L_PAREN bool_exp R_PAREN			{printf("relation_exp -> L_PAREN bool_exp R_PAREN\n");}
        ;


comp: EQ	{printf("comp -> EQ\n");}	
	| NEQ	{printf("comp -> NEQ\n");}
	| LT	{printf("comp -> LT\n");}
	| GT 	{printf("comp -> GT\n");}
	| LTE	{printf("comp -> LTE\n");}
	| GTE	{printf("comp -> GTE\n");}
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
