/*
 * SymbolTable.cpp
 *
 *  Created on: 31 maj 2014
 *      Author: Jacek
 */

#include "SymbolTable.h"

SymbolTable::SymbolTable() {

}

void SymbolTable::addSymbol(const symbol& symbol) {
	symbols.push_back(symbol);
}

symbol* SymbolTable::findSymbol(string identifier) {
	for (list<symbol>::iterator it = symbols.begin(); it != symbols.end(); it++) {
	    if((*it).identifier == identifier) {
	    	return &(*it);
	    }
	}
	return NULL;
}



