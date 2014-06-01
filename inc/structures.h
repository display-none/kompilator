/*
 * structures.h
 *
 *  Created on: 31 maj 2014
 *      Author: Jacek
 */

#ifndef STRUCTURES_H_
#define STRUCTURES_H_

#include <string>

using namespace std;

struct symbol {
	string identifier;
	long value;
	bool isConst;
	int dataOffset;
	bool isInitialized;
	symbol(string identifier, long value): identifier(identifier), value(value), isConst(true), dataOffset(-1), isInitialized(true) { }
	symbol(string identifier, int dataOffset): identifier(identifier), value(-1), isConst(false), dataOffset(dataOffset), isInitialized(false) { }
};

enum op {
	SCAN, PRINT, LOAD, STORE, ADD, SUB, SHR, SHL, INC, DEC, ZERO, JUMP, JZ, JG, JODD, HALT
};

extern string opStrings[];


struct codeLine {
	op oper;
	int arg;
	bool hasArg;
	codeLine(op oper, int arg): oper(oper), arg(arg), hasArg(true) { }
	codeLine(op oper): oper(oper), arg(0), hasArg(false) { }
};

struct lbl {
	codeLine* forJump;
	codeLine* forFalseCondJump;
};


#endif /* STRUCTURES_H_ */
