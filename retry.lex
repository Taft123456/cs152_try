%{
	#include <iostream>
	#define YY_DECL yy::parser::symbol_type yylex()
	#include "parser.tab.hh"
	static yy::location loc;
	int row = 1;
	int col = 0;
%}

%option noyywrap 

%{
	#define YY_USER_ACTION loc.columns(yyleng);
%}

DIGI   [0-9]
LETT   [a-zA-Z]
NLET   ({DIGI}|(_))

%%

%{
loc.step(); 
%}

"function"       {col += yyleng; return yy::parser::make_FUNCTION(loc);}
"beginparams"    {col += yyleng; return yy::parser::make_BEGIN_PARAMS(loc);} 	
"endparams"      {col += yyleng; return yy::parser::make_END_PARAMS(loc);}
"beginlocals"    {col += yyleng; return yy::parser::make_BEGIN_LOCALS(loc);}
"endlocals"      {col += yyleng; return yy::parser::make_END_LOCALS(loc);}
"beginbody"      {col += yyleng; return yy::parser::make_BEGIN_BODY(loc);}
"endbody"        {col += yyleng; return yy::parser::make_END_BODY(loc);}
"integer"        {col += yyleng; return yy::parser::make_INTEGER(loc);}
"array"          {col += yyleng; return yy::parser::make_ARRAY(loc);}
"of"             {col += yyleng; return yy::parser::make_OF(loc);}
"if"             {col += yyleng; return yy::parser::make_IF(loc);}
"then"           {col += yyleng; return yy::parser::make_THEN(loc);}
"endif"          {col += yyleng; return yy::parser::make_ENDIF(loc);}
"else"           {col += yyleng; return yy::parser::make_ELSE(loc);}
"while"          {col += yyleng; return yy::parser::make_WHILE(loc);}
"do"             {col += yyleng; return yy::parser::make_DO(loc);}
"beginloop"      {col += yyleng; return yy::parser::make_BEGINLOOP(loc);}
"endloop"        {col += yyleng; return yy::parser::make_ENDLOOP(loc);}
"continue"       {col += yyleng; return yy::parser::make_CONTINUE(loc);}
"read"           {col += yyleng; return yy::parser::make_READ(loc);}
"write"          {col += yyleng; return yy::parser::make_WRITE(loc);}
"and"            {col += yyleng; return yy::parser::make_AND(loc);}
"or"             {col += yyleng; return yy::parser::make_OR(loc);}
"not"            {col += yyleng; return yy::parser::make_NOT(loc);}
"true"           {col += yyleng; return yy::parser::make_TRUE(loc);}
"false"          {col += yyleng; return yy::parser::make_FALSE(loc);}
"return"	 {col += yyleng; return yy::parser::make_RETURN(loc);}

"-"	         {col += yyleng; return yy::parser::make_SUB(loc);}			
"+"	         {col += yyleng; return yy::parser::make_ADD(loc);}
"*"              {col += yyleng; return yy::parser::make_MULT(loc);}
"/"              {col += yyleng; return yy::parser::make_DIV(loc);}
"%"              {col += yyleng; return yy::parser::make_MOD(loc);}

"=="   	         {col += yyleng; return yy::parser::make_EQ(loc);}		
"<>"	         {col += yyleng; return yy::parser::make_NEQ(loc);}
"<"              {col += yyleng; return yy::parser::make_LT(loc);}
">"              {col += yyleng; return yy::parser::make_GT(loc);}
"<="             {col += yyleng; return yy::parser::make_LTE(loc);}
">="             {col += yyleng; return yy::parser::make_GTE(loc);}

";"  	         {col += yyleng; return yy::parser::make_SEMICOLON(loc);}
":"	         {col += yyleng; return yy::parser::make_COLON(loc);}
","	         {col += yyleng; return yy::parser::make_COMMA(loc);}
"("	         {col += yyleng; return yy::parser::make_L_PAREN(loc);}
")"	         {col += yyleng; return yy::parser::make_R_PAREN(loc);}
"["	         {col += yyleng; return yy::parser::make_L_SQUARE_BRACKET(loc);}
"]"	         {col += yyleng; return yy::parser::make_R_SQUARE_BRACKET(loc);}
":="	         {col += yyleng; return yy::parser::make_ASSIGN(loc);}

{DIGI}+          {col += yyleng; return yy::parser::make_NUMBER(atoi(yytext), loc);}	

{LETT}({LETT}|{DIGI})*((_)+({LETT}|{DIGI})+)*   {col += yyleng; return yy::parser::make_IDENT(yytext, loc);}	

[ \t]+         		{col += yyleng;}	

"##".*			{col += yyleng;}	

\n           		{row++; col = 0;}	

{NLET}({LETT}|{DIGI})*((_)+({LETT}|{DIGI})+)*(_)*  {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", row, col, yytext);
                                                    col += yyleng;}	


{LETT}({LETT}|{DIGI})*((_)+({LETT}|{DIGI})+)*(_)+  {printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", row, col, yytext);
                                                    col += yyleng;}	


.              		{printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", row, col, yytext); col += yyleng;}


<<EOF>>	       {col += yyleng; return yy::parser::make_END(loc);}

%%
