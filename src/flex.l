
%x COMMENT
%option yylineno

%{
#include <stdio.h>
#include "structures.h"
#include "bison.tab.h"

using namespace std;

%}

%%

CONST							{ return CONST; }
VAR								{ return VAR; }
BEGIN							{ return _BEGIN; }
END								{ return END; }
IF								{ return IF; }
THEN							{ return THEN; }
ELSE							{ return ELSE; }
WHILE							{ return WHILE; }
DO								{ return DO; }
READ							{ return READ; }
WRITE							{ return WRITE; }


[0-9]+							{
									yylval.integer = atol(yytext);
									return num;
								}

":="							{ return OP_ASSGN; }
"=="							{ return OP_EQ; }
"!="							{ return OP_NEQ; }
">="							{ return OP_GTEQ; }
"<="							{ return OP_LTEQ; }

[-+*/%=><;]						{ return *yytext; }

[_a-z]+							{
									yylval.string = (char *) strdup(yytext);
									return identifier;
								}

[ \t\r\n]*						/* eat white things */


"(*"							BEGIN(COMMENT);
<COMMENT>.|\n					/* eat it */
<COMMENT>"*)"					BEGIN(INITIAL);


%%
