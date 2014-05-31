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
	int value;
	bool isConst;
	symbol(string identifier, int value, bool isConst): identifier(identifier), value(value), isConst(isConst) { }
};

struct lbl {
	int forJump;
	int forFalseCondJump;
};



#endif /* STRUCTURES_H_ */
