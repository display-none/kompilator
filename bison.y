%{
	#include <stdio.h>

	int yylex(void);
	void yyerror(char *);
	
%}

%union{ char* string; int integer; }

%token <string> CONST
%token <string> VAR
%token <string> _BEGIN
%token <string> END
%token <string> IF
%token <string> THEN
%token <string> ELSE
%token <string> WHILE
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