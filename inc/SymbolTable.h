/*
 * SymbolTable.h
 *
 *  Created on: 31 maj 2014
 *      Author: Jacek
 */

#ifndef SYMBOLTABLE_H_
#define SYMBOLTABLE_H_

#include <cstdlib>
#include <string>
#include <list>

#include "structures.h"

using namespace std;

class SymbolTable {
private:
	list<symbol> symbols;
public:
	SymbolTable();
	void addNewSymbol(string identifier, int value, bool isConst);
	symbol* findSymbol(string identifier);
};



#endif /* SYMBOLTABLE_H_ */
