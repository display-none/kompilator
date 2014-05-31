/*
 * SymbolTable.cpp
 *
 *  Created on: 31 maj 2014
 *      Author: Jacek
 */

#include "SymbolTable.h"

SymbolTable::SymbolTable() {

}

void SymbolTable::addNewSymbol(string identifier, int value, bool isConst) {
	symbols.push_back(symbol(identifier, value, isConst));
}

symbol* SymbolTable::findSymbol(string identifier) {
	for (list<symbol>::iterator it = symbols.begin(); it != symbols.end(); it++) {
	    if((*it).identifier == identifier) {
	    	return &(*it);
	    }
	}
	return NULL;
}



