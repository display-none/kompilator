%{
	#include <stdio.h>
	#include <string>
	
	#include "Code.h"
	#include "SymbolTable.h"
	#include "structures.h"
	
	using namespace std;
	
	#define MAX_LINE_SIZE 1000
	
	char tmp[MAX_LINE_SIZE];

	extern int yylineno;
	
	int yylex(void);
	void yyerror(char *);
	void handleError();
	
	SymbolTable symbolTable;
	Code code;
	
	op currentFalseConditionCommand = HALT;			//will keep JG or JZ depending on what was the preferred command by last parsed condition
	
	int dataOffset = 3;				//start storing variables from 3rd cell, cause the first three can be of better use
	int reserveDataLocation();
	
	bool isPowerOf2(long x);
	
	symbol* checkContext(string identifier);
	void checkContextAdd(string identifier);
	symbol* checkContextChange(string identifier);
	
	void addNewConstIfNotAlreadyDefined(string identifier, long value);
	void addNewVariableIfNotAlreadyDefined(string identifier);
	
	void addConstructNumberCode(long value);
	void addConstPrintingCode(symbol* symbol);
	
%}

%union{ char* string; 
		long integer;
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

%token OP_ASSGN ":="
%token OP_EQ "=="
%token OP_NEQ "!="
%token OP_GTEQ ">="
%token OP_LTEQ "<="

%token <integer> num
%token <string> identifier

%left ":="
%left '+' '-'
%left '*' '/' '%'
%right '^'

%start program

%%

program:
		CONST cdeclarations VAR vdeclarations _BEGIN commands END	{	code.addLine(HALT); }
		;
		
cdeclarations:
		cdeclarations identifier '=' num 			{ addNewConstIfNotAlreadyDefined($2, $4); }
		|
		;
		
vdeclarations:
		vdeclarations identifier 			{ addNewVariableIfNotAlreadyDefined($2); }
		|
		;
		
commands:
		commands command
		|
		;
		
command:
		identifier ":=" expression ';'
					{
						symbol* symbol = checkContextChange($1);
						symbol->isInitialized = true;
						code.addLine(STORE, symbol->dataOffset);
					}
		| IF condition 			{	$1 = new lbl(); $1->forFalseCondJump = code.reserveLine(currentFalseConditionCommand); }
			THEN commands 		{	$1->forJump = code.reserveLine(); }
			ELSE 				{	code.backPatch($1->forFalseCondJump, code.generateLabel()); }
			commands END		{	code.backPatch($1->forJump, JUMP, code.generateLabel()); delete $1;}
			
		| WHILE 				{	$1 = new lbl(); $1->forJump = new codeLine(JUMP, code.generateLabel()); }
			condition 			{	$1->forFalseCondJump = code.reserveLine(currentFalseConditionCommand); }
			DO commands END		{	code.addLine(*($1->forJump));
									code.backPatch($1->forFalseCondJump, code.generateLabel()); delete $1->forJump; delete $1; }
		| READ identifier ';'
					{
						symbol* symbol = checkContextChange($2);
						symbol->isInitialized = true;
						code.addLine(SCAN, symbol->dataOffset);
					}
		| WRITE identifier ';'
					{
						symbol* symbol = checkContext($2);
						if(symbol->isConst) {
							addConstPrintingCode(symbol);
						} else {
							code.addLine(PRINT, symbol->dataOffset);
						}
					}
		;

expression:
		num										{	addConstructNumberCode($1); }
		| identifier							{	
													symbol* symbol = checkContext($1);
													if(symbol->isConst) {
														addConstructNumberCode(symbol->value);
													} else {
														code.addLine(LOAD, symbol->dataOffset); 
													}
												}
		| identifier '+' identifier				{	
													symbol* s1 = checkContext($1);
													symbol* s2 = checkContext($3);
													if(s1->isConst && s2->isConst) {
														addConstructNumberCode(s1->value + s2->value);
													} else {
														if(s1->isConst) {
															addConstructNumberCode(s1->value);
															code.addLine(ADD, s2->dataOffset);
														} else if(s2->isConst) {
															addConstructNumberCode(s2->value);
															code.addLine(ADD, s1->dataOffset);
														} else {
															code.addLine(LOAD, s1->dataOffset);
															code.addLine(ADD, s2->dataOffset);
														}
													}
												}
		| identifier '-' identifier				{	
													symbol* s1 = checkContext($1);
													symbol* s2 = checkContext($3);
													if(s1->isConst && s2->isConst) {
														addConstructNumberCode(s1->value - s2->value);
													} else {
														if(s1->isConst) {
															addConstructNumberCode(s1->value);
															code.addLine(SUB, s2->dataOffset);
														} else if(s2->isConst) {
															addConstructNumberCode(s2->value);			//construct a constant
															code.addLine(STORE, 0);							//store it in register 0
															code.addLine(LOAD, s1->dataOffset);				//load first
															code.addLine(SUB, 0);							//subtract the constant
														} else {
															code.addLine(LOAD, s1->dataOffset);
															code.addLine(SUB, s2->dataOffset);
														}
													}
												}
		| identifier '*' identifier				{
													symbol* s1 = checkContext($1);
													symbol* s2 = checkContext($3);
													if(s1->isConst && s2->isConst) {
														addConstructNumberCode(s1->value * s2->value);
													} else {
														if(s1->isConst) {
															code.addLine(LOAD, s2->dataOffset);				//load second
															code.addLine(STORE, 0);							//store its copy in register 0
															long value = s1->value;
															list<codeLine> multiplyCode;				//will keep the multiplying code, will be pushed front
															while(value != 1) {
																if(value % 2 == 0) {
																	multiplyCode.push_front(codeLine(SHL));	//either shift left
																	value = value / 2;
																} else {
																	multiplyCode.push_front(codeLine(ADD, 0));	//or add original number
																	value = value - 1;
																}
															}
															code.addLines(multiplyCode);
														} else if(s2->isConst) {
															code.addLine(LOAD, s1->dataOffset);				//load first
															code.addLine(STORE, 0);							//store its copy in register 0
															long value = s2->value;
															list<codeLine> multiplyCode;				//will keep the multiplying code, will be pushed front
															while(value != 1) {
																if(value % 2 == 0) {
																	multiplyCode.push_front(codeLine(SHL));	//either shift left
																	value = value / 2;
																} else {
																	multiplyCode.push_front(codeLine(ADD, 0));	//or add original number
																	value = value - 1;
																}
															}
															code.addLines(multiplyCode);
														} else {
															if(s1->identifier == s2->identifier) {	//adding second to itself i times (i = first)
																code.addLine(LOAD, s1->dataOffset);				//load first
																lbl label1;
																label1.forFalseCondJump = code.reserveLine(JZ);	//reserve space for jump when first == 0
																code.addLine(STORE, 1);							//store first in register 1
																code.addLine(STORE, 2);							//store in register 2 since first == second
																code.addLine(ZERO);
																code.addLine(STORE, 0);							//first result is zero
																
																lbl start;										//place to jump when we still have to add
																start.forFalseCondJump = new codeLine(JG, code.generateLabel());
																code.addLine(LOAD, 0);							//load current result
																code.addLine(ADD, 2);
																code.addLine(STORE, 0);							//store result in register 0
																code.addLine(LOAD, 1);							//load i
																code.addLine(DEC);								//decrement
																code.addLine(STORE, 1);							//store i in register 1
																code.addLine(*(start.forFalseCondJump));			//if i > 0 jump to start
																
																code.addLine(LOAD, 0);
																
																code.backPatch(label1.forFalseCondJump, code.generateLabel());
															
																delete start.forFalseCondJump;
															} else {	//adding second to itself i times (i = first)
																code.addLine(LOAD, s1->dataOffset);				//load first
																lbl label1;
																label1.forFalseCondJump = code.reserveLine(JZ);	//reserve space for jump when first == 0
																code.addLine(STORE, 1);							//store first in register 1
																code.addLine(LOAD, s2->dataOffset);				//load second
																lbl label2;
																label2.forFalseCondJump = code.reserveLine(JZ);	//reserve space for jump when second == 0
																code.addLine(STORE, 2);
																code.addLine(ZERO);
																code.addLine(STORE, 0);							//first result is zero
																
																lbl start;										//place to jump when we still have to add
																start.forFalseCondJump = new codeLine(JG, code.generateLabel());
																code.addLine(LOAD, 0);							//load current result
																code.addLine(ADD, 2);
																code.addLine(STORE, 0);							//store result in register 0
																code.addLine(LOAD, 1);							//load i
																code.addLine(DEC);								//decrement
																code.addLine(STORE, 1);							//store i in register 1
																code.addLine(*(start.forFalseCondJump));			//if i > 0 jump to start
																
																code.addLine(LOAD, 0);
																
																code.backPatch(label1.forFalseCondJump, code.generateLabel());
																code.backPatch(label2.forFalseCondJump, code.generateLabel());
																
																delete start.forFalseCondJump;
															}
														}
													}
													
												}
		| identifier '/' identifier				{
													symbol* s1 = checkContext($1);
													symbol* s2 = checkContext($3);
													if(s2->isConst && s2->value == 0) {
														sprintf(tmp, "Error in line%d: dividing by zero! Don't do it dummy\n", yylineno);
														handleError();
													}
													if(s1->isConst && s2->isConst) {
														addConstructNumberCode(s1->value / s2->value);
													} else {
														if(s2->isConst && isPowerOf2(s2->value)) {
															code.addLine(LOAD, s1->dataOffset);				//load first
															long value = s2->value;
															while(value != 1) {
																code.addLine(SHR);							//shift right = divide by 2
																value = value / 2;
															}
														} else if(s1->isConst && s1->value == 0) {
															code.addLine(ZERO);
														} else if(s1->identifier == s2->identifier) {
															code.addLine(ZERO);
															code.addLine(INC);
														} else {	/* i will count number of subtractions => result */
															if(s1->isConst) {
																addConstructNumberCode(s1->value + 1);
															} else {
																code.addLine(LOAD, s1->dataOffset);
																code.addLine(INC);					//increment to correctly compute ceil
															}
															code.addLine(STORE, 1);					//store first in register 1
															code.addLine(LOAD, s2->dataOffset);		//load second
															code.addLine(STORE, 2);					//store second in register 2
															code.addLine(ZERO);
															code.addLine(STORE, 0);					//store i = 0 in register 0
															
															lbl start;
															start.forFalseCondJump = new codeLine(JG, code.generateLabel());
															code.addLine(LOAD, 0);					//load i
															code.addLine(INC);						//increment i
															code.addLine(STORE, 0);					//store i
															code.addLine(LOAD, 1);					//load current first
															code.addLine(SUB, 2);					//subtract second
															code.addLine(STORE, 1);					//store current first
															code.addLine(*(start.forFalseCondJump));
															
															code.addLine(LOAD, 0);					//the result is i
															code.addLine(DEC);						//need to decrement since we computed ceil(first / second)
															
															delete start.forFalseCondJump;
														}
													}
												}
		| identifier '%' identifier				{
													symbol* s1 = checkContext($1);
													symbol* s2 = checkContext($3);
													if(s1->isConst && s2->isConst) {
														addConstructNumberCode(s1->value % s2->value);
													} else {
														if(s2->isConst) {
															addConstructNumberCode(s2->value);
														} else {
															code.addLine(LOAD, s2->dataOffset);
														}
														code.addLine(STORE, 2);
														
														if(s1->isConst) {
															addConstructNumberCode(s1->value);
														} else {
															code.addLine(LOAD, s1->dataOffset);
														}
														code.addLine(STORE, 1);
														
														
														lbl loop;
														loop.forJump = new codeLine(JUMP, code.generateLabel());
														
																								//here current result is in A
														code.addLine(SUB, 2);					//subtract original modulus
														lbl whenFound;
														whenFound.forFalseCondJump = code.reserveLine(JZ);
																								//there is still room for subtractions
														code.addLine(STORE, 1);
														code.addLine(LOAD, 2);					//load original modulus
														code.addLine(STORE, 0);					//store new modulus in register 0
														
														code.addLine(LOAD, 1);					//load current result
														
														loop.forFalseCondJump = new codeLine(JG, code.generateLabel());
														code.addLine(STORE, 1);					//store current result in register 1
														code.addLine(LOAD, 0);					//load current modulus
														code.addLine(SHL);						//multiply current modulus by 2
														code.addLine(STORE, 0);					//save current modulus
														code.addLine(LOAD, 1);					//result is in register 1
														code.addLine(SUB, 0);					//subtract the modulus
														code.addLine(*(loop.forFalseCondJump));	//when result > 0, do the loop again
														code.addLine(LOAD, 1);					//load current result
														code.addLine(*(loop.forJump));			//go back to the beginning
														
														code.backPatch(whenFound.forFalseCondJump, code.generateLabel());
																					
																					//the result is in register 1, but it could be equal to modulus
														lbl littleIf;
														
														code.addLine(LOAD, 2);		//load modulus
														code.addLine(SUB, 1);		//subtract the result
														littleIf.forFalseCondJump = code.reserveLine(JZ);
															code.addLine(LOAD, 1);		//if it's > 0, the result is correct
														littleIf.forJump = code.reserveLine();
														code.backPatch(littleIf.forFalseCondJump, code.generateLabel());
															code.addLine(ZERO);			//if it's == 0, the result should be 0
														code.backPatch(littleIf.forJump, JUMP, code.generateLabel());
													}
												}
		;
		
condition:
		identifier "==" identifier			{	/* TRUE - A contains 0; FALSE - A contains sth > 0 */
												symbol* s1 = checkContext($1);
												symbol* s2 = checkContext($3);
												if(s1->isConst && s2->isConst) {
													if(s1->value == s2->value) {
														code.addLine(ZERO);
													} else {
														code.addLine(ZERO);
														code.addLine(INC);
													}
												} else {
													if(s1->isConst) {
														addConstructNumberCode(s1->value);		//prepare a constant
														code.addLine(STORE, 1);					//store its copy in register 1
														code.addLine(SUB, s2->dataOffset);		//subtract second argument, if second >= first A should contain 0
														code.addLine(STORE, 2);					//move the result to register 2
														code.addLine(LOAD, s2->dataOffset);		//load the second argument
														code.addLine(SUB, 1);					//subtract the constant, if first >= second A should contain 0
														code.addLine(ADD, 2);					//add previous result, if first == second A should contain 0
													} else if(s2->isConst) {
														addConstructNumberCode(s2->value);		//prepare a constant
														code.addLine(STORE, 1);					//store its copy in register 1
														code.addLine(SUB, s1->dataOffset);		//subtract first argument, if first >= second A should contain 0
														code.addLine(STORE, 2);					//move the result to register 2
														code.addLine(LOAD, s1->dataOffset);		//load the first argument
														code.addLine(SUB, 1);					//subtract the constant, if second >= first A should contain 0
														code.addLine(ADD, 2);					//add previous result, if second == first A should contain 0
													} else {
														code.addLine(LOAD, s1->dataOffset);		//load first argument
														code.addLine(STORE, 1);					//store its copy in register 1
														code.addLine(LOAD, s2->dataOffset);		//load second argument
														code.addLine(STORE, 2);					//store its copy in register 2
														code.addLine(SUB, 1);					//subtract first argument, if first >= second A should contain 0
														code.addLine(STORE, 0);					//move the result to register 0
														code.addLine(LOAD, 1);					//load first argument from register 1
														code.addLine(SUB, 2);					//subtract second argument, if second >= first A should contain 0
														code.addLine(ADD, 0);					//add previous result, if first == second A should contain 0
													}
												}
												currentFalseConditionCommand = JG;				//false condition jump on > 0
											}
		| identifier "!=" identifier		{	/* TRUE - A contains sth > 0; FALSE - A contains 0 */
												symbol* s1 = checkContext($1);
												symbol* s2 = checkContext($3);
												if(s1->isConst && s2->isConst) {
													if(s1->value != s2->value) {
														code.addLine(ZERO);
														code.addLine(INC);
													} else {
														code.addLine(ZERO);
													}
												} else {
													if(s1->isConst) {
														addConstructNumberCode(s1->value);		//prepare a constant
														code.addLine(STORE, 1);					//store its copy in register 1
														code.addLine(SUB, s2->dataOffset);		//subtract second argument, if second >= first A should contain 0
														code.addLine(STORE, 2);					//move the result to register 2
														code.addLine(LOAD, s2->dataOffset);		//load the second argument
														code.addLine(SUB, 1);					//subtract the constant, if first >= second A should contain 0
														code.addLine(ADD, 2);					//add previous result, if first == second A should contain 0
													} else if(s2->isConst) {
														addConstructNumberCode(s2->value);		//prepare a constant
														code.addLine(STORE, 1);					//store its copy in register 1
														code.addLine(SUB, s1->dataOffset);		//subtract first argument, if first >= second A should contain 0
														code.addLine(STORE, 2);					//move the result to register 2
														code.addLine(LOAD, s1->dataOffset);		//load the first argument
														code.addLine(SUB, 1);					//subtract the constant, if second >= first A should contain 0
														code.addLine(ADD, 2);					//add previous result, if second == first A should contain 0
													} else {
														code.addLine(LOAD, s1->dataOffset);		//load first argument
														code.addLine(STORE, 1);					//store its copy in register 1
														code.addLine(LOAD, s2->dataOffset);		//load second argument
														code.addLine(STORE, 2);					//store its copy in register 2
														code.addLine(SUB, 1);					//subtract first argument, if first >= second A should contain 0
														code.addLine(STORE, 0);					//move the result to register 0
														code.addLine(LOAD, 1);					//load first argument from register 1
														code.addLine(SUB, 2);					//subtract second argument, if second >= first A should contain 0
														code.addLine(ADD, 0);					//add previous result, if first == second A should contain 0
													}
												}
												currentFalseConditionCommand = JZ;				//false condition jump on == 0
											}
		| identifier '<' identifier			{	/* TRUE - A contains sth > 0; FALSE - A contains 0 */
												symbol* s1 = checkContext($1);
												symbol* s2 = checkContext($3);
												if(s1->isConst && s2->isConst) {
													if(s1->value < s2->value) {
														code.addLine(ZERO);
														code.addLine(INC);
													} else {
														code.addLine(ZERO);
													}
												} else {
													if(s1->isConst) {
														addConstructNumberCode(s1->value);		//prepare a constant
														code.addLine(STORE, 1);					//store its copy in register 1
														code.addLine(LOAD, s2->dataOffset);		//load the second argument
														code.addLine(SUB, 1);					//subtract the constant, if first < second A should contain sth > 0
													} else if(s2->isConst) {
														addConstructNumberCode(s2->value);		//prepare a constant
														code.addLine(SUB, s1->dataOffset);		//subtract first argument, if first < second A should contain sth > 0
													} else {
														code.addLine(LOAD, s2->dataOffset);		//load second argument
														code.addLine(SUB, s1->dataOffset);		//subtract first argument, if first < second A should contain sth > 0
													}
												}
												currentFalseConditionCommand = JZ;				//false condition jump on == 0
											}
		| identifier '>' identifier			{	/* TRUE - A contains sth > 0; FALSE - A contains 0 */
												symbol* s1 = checkContext($1);
												symbol* s2 = checkContext($3);
												if(s1->isConst && s2->isConst) {
													if(s1->value > s2->value) {
														code.addLine(ZERO);
														code.addLine(INC);
													} else {
														code.addLine(ZERO);
													}
												} else {
													if(s1->isConst) {
														addConstructNumberCode(s1->value);		//prepare a constant
														code.addLine(SUB, s2->dataOffset);		//subtract second, if first > second A should contain sth > 0
													} else if(s2->isConst) {
														addConstructNumberCode(s2->value);		//prepare a constant
														code.addLine(STORE, 2);					//store its copy in register 2
														code.addLine(LOAD, s1->dataOffset);		//load first argument
														code.addLine(SUB, 2);					//subtract the constant, if first > second A should contain sth > 0
													} else {
														code.addLine(LOAD, s1->dataOffset);		//load first argument
														code.addLine(SUB, s2->dataOffset);		//subtract second argument, if first > second A should contain sth > 0
													}
												}
												currentFalseConditionCommand = JZ;				//false condition jump on == 0
											}
		| identifier "<=" identifier		{	/* TRUE - A contains 0; FALSE - A contains sth > 0 */
												symbol* s1 = checkContext($1);
												symbol* s2 = checkContext($3);
												if(s1->isConst && s2->isConst) {
													if(s1->value <= s2->value) {
														code.addLine(ZERO);
													} else {
														code.addLine(ZERO);
														code.addLine(INC);
													}
												} else {
													if(s1->isConst) {
														addConstructNumberCode(s1->value);		//prepare a constant
														code.addLine(SUB, s2->dataOffset);		//subtract second, if first <= second A should contain 0
													} else if(s2->isConst) {
														addConstructNumberCode(s2->value);		//prepare a constant
														code.addLine(STORE, 2);					//store its copy in register 2
														code.addLine(LOAD, s1->dataOffset);		//load first argument
														code.addLine(SUB, 2);					//subtract the constant, if first <= second A should contain 0
													} else {
														code.addLine(LOAD, s1->dataOffset);		//load first argument
														code.addLine(SUB, s2->dataOffset);		//subtract second argument, if first <= second A should contain 0
													}
												}
												currentFalseConditionCommand = JG;				//false condition jump on sth > 0
											}
		| identifier ">=" identifier		{	/* TRUE - A contains 0; FALSE - A contains sth > 0 */
												symbol* s1 = checkContext($1);
												symbol* s2 = checkContext($3);
												if(s1->isConst && s2->isConst) {
													if(s1->value < s2->value) {
														code.addLine(ZERO);
													} else {
														code.addLine(ZERO);
														code.addLine(INC);
													}
												} else {
													if(s1->isConst) {
														addConstructNumberCode(s1->value);		//prepare a constant
														code.addLine(STORE, 1);					//store its copy in register 1
														code.addLine(LOAD, s2->dataOffset);		//load the second argument
														code.addLine(SUB, 1);					//subtract the constant, if first >= second A should contain 0
													} else if(s2->isConst) {
														addConstructNumberCode(s2->value);		//prepare a constant
														code.addLine(SUB, s1->dataOffset);		//subtract first argument, if first >= second A should contain 0
													} else {
														code.addLine(LOAD, s2->dataOffset);		//load second argument
														code.addLine(SUB, s1->dataOffset);		//subtract first argument, if first >= second A should contain 0
													}
												}
												currentFalseConditionCommand = JG;				//false condition jump on sth > 0
											}
		;


%%


bool isPowerOf2(long x) {
	return x > 0 && !(x & (x-1));
}

int reserveDataLocation() {
	return dataOffset++;
}

symbol* checkContext(string identifier) {
	symbol* symbol = symbolTable.findSymbol(identifier);
	if(symbol == NULL) {
		sprintf(tmp, "Error in line %d: no symbol with identifier %s declared\n", yylineno, identifier.c_str());
		handleError();
	}
	if(!symbol->isInitialized) {
		sprintf(tmp, "Error in line %d: variable %s hasn't been initialized\n", yylineno, identifier.c_str());
		handleError();
	}
	return symbol;
}

void checkContextAdd(string identifier) {
	symbol* symbol = symbolTable.findSymbol(identifier);
	if(symbol != NULL) {
		sprintf(tmp, "Error in line %d: identifier %s is already defined\n", yylineno, identifier.c_str());
		handleError();
	}
}

symbol* checkContextChange(string identifier) {
	symbol* symbol = symbolTable.findSymbol(identifier);
	if(symbol == NULL) {
		sprintf(tmp, "Error in line %d: identifier %s was not declared\n", yylineno, identifier.c_str());
		handleError();
	}
	if(symbol->isConst) {
		sprintf(tmp, "Error in line %d: cannot change a constant\n", yylineno);
		handleError();
	}
	return symbol;
}

void addConstructNumberCode(long value) {
	list<codeLine> constCode;
	while(value != 0) {
		if(value % 2 == 0) {
			constCode.push_front(codeLine(SHL));
			value = value / 2;
		} else {
			constCode.push_front(codeLine(INC));
			value = value - 1;
		}
	}
	constCode.push_front(codeLine(ZERO));
	code.addLines(constCode);
}

void addConstPrintingCode(symbol* symbol) {
	addConstructNumberCode(symbol->value);
	code.addLine(STORE, 1);
	code.addLine(PRINT, 1);
}

void addNewConstIfNotAlreadyDefined(string identifier, long value) {
	checkContextAdd(identifier);
	symbolTable.addSymbol(symbol(identifier, value));
}

void addNewVariableIfNotAlreadyDefined(string identifier) {
	checkContextAdd(identifier);
	int offset = reserveDataLocation();
	symbolTable.addSymbol(symbol(identifier, offset));
}

void handleError() {
	yyerror(tmp);
	exit(1);
}

void yyerror(char *s) {
	printf("%s", s);
	printf("%d", yylineno);
}

int main(void) {
	yyparse();
	
	code.saveToFile();
	return 0;
} 