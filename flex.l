
%x COMMENT

%{
#include <stdio.h>
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
									yylval.integer = atoi(yytext);
									return num;
								}

":="							{ return *yytext; }
"=="							{ return *yytext; }
"!="							{ return *yytext; }
">="							{ return *yytext; }
"<="							{ return *yytext; }

[-+*/%=><;]						{ return *yytext; }

[_a-z]+							{
									yylval.string = yytext;
									return identifier;
								}

[ \t\r\n]*						/* eat white things */


"(*"							BEGIN(COMMENT);
<COMMENT>.|\n					/* eat it */
<COMMENT>"*)"					BEGIN(INITIAL);


%%
