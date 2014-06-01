/*
 * Code.cpp
 *
 *  Created on: 31 maj 2014
 *      Author: Jacek
 */

#include "Code.h"

Code::Code() {
	codeOffset = 0;
}

void Code::addLine(op operation, int argument) {
	codeOffset++;
	code.push_back(codeLine(operation, argument));
}

void Code::addLine(op operation) {
	codeOffset++;
	code.push_back(codeLine(operation));
}

void Code::addLine(codeLine line) {
	codeOffset++;
	code.push_back(line);
}

void Code::addLines(list<codeLine>& list) {
	codeOffset += list.size();
	code.splice(code.end(), list);
}

codeLine* Code::reserveLine() {
	return reserveLine(HALT);		//could be anything, this will be changed later
}

codeLine* Code::reserveLine(op operation) {
	codeOffset++;
	code.push_back(codeLine(operation));
	return &(code.back());
}

int Code::generateLabel() {
	return codeOffset;
}

void Code::backPatch(codeLine* lineToBackPatch, op operation, int label) {
	lineToBackPatch->oper = operation;
	backPatch(lineToBackPatch, label);
}

void Code::backPatch(codeLine* lineToBackPatch, int label) {
	lineToBackPatch->hasArg = true;
	lineToBackPatch->arg = label;
}

void Code::saveToFile() {
	printf("code offset: %d", codeOffset);
	ofstream file ("code");

	for(list<codeLine>::iterator it = code.begin(); it != code.end(); it++) {
		file << opStrings[(*it).oper];
		if((*it).hasArg) {
			file << " " << (*it).arg;
		}
		file << "\n";
	}
	file.close();
}

