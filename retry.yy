%{
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
	/* define the sturctures using as types for non-terminals */
struct s
{
	string output;
	list<string> id;
};
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

	/* define your symbol table, global variables,
	 * list of keywords or any function you may need here */
map<string, int> symbols;
string labels()
{
        string r = "__temp__" + atoi(num);
        num++;
	return r;
};	
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
%type <s> declarations declaration
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
