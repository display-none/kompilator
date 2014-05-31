%{
	#include <stdio.h>
	#include <string>
	
	#include "SymbolTable.h"
	#include "structures.h"
	
	using namespace std;

	int yylex(void);
	void yyerror(char *);
	
	SymbolTable symbolTable;
%}

%union{ char* string; 
		int integer;
		lbl* label;	/* for backpatching */
	}

%token <string> CONST
%token <string> VAR
%token <string> _BEGIN
%token <string> END
%token <label> IF
%token <string> THEN
%token <string> ELSE
%token <label> WHILE
%token <string> DO
%token <string> READ
%token <string> WRITE

%token <integer> num
%token <string> identifier

%left '+' '-'
%left '*' '/' '%'
%right '^'

%start program

%%

program:
		CONST cdeclarations VAR vdeclarations _BEGIN commands END
		;
		
cdeclarations:
		cdeclarations identifier '=' num
		|
		;
		
vdeclarations:
		vdeclarations identifier
		|
		;
		
commands:
		commands command
		|
		;
		
command:
		identifier ":=" expression ';'
		| IF condition THEN commands ELSE commands END
		| WHILE condition DO commands END
		| READ identifier ';'
		| WRITE identifier ';'
		;

expression:
		num
		| identifier
		| identifier '+' identifier
		| identifier '-' identifier
		| identifier '*' identifier
		| identifier '/' identifier
		| identifier '%' identifier
		;
		
condition:
		identifier "==" identifier
		| identifier "!=" identifier
		| identifier '<' identifier
		| identifier '>' identifier
		| identifier "<=" identifier
		| identifier ">=" identifier
		;


%%

void yyerror(char *s) {
	printf("%s", s);
}

int main(void) {
	yyparse();
	return 0;
} 