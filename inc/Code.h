/*
 * Code.h
 *
 *  Created on: 31 maj 2014
 *      Author: Jacek
 */

#ifndef CODE_H_
#define CODE_H_

#include <list>
#include <fstream>

#include "structures.h"

using namespace std;

class Code {
private:
	list<codeLine> code;
	int codeOffset;
public:
	Code();

	void addLine(op operation, int argument);
	void addLine(op operation);
	void addLine(codeLine line);
	void addLines(list<codeLine>& list);
	codeLine* reserveLine();
	codeLine* reserveLine(op operation);

	int generateLabel();
	void backPatch(codeLine* lineToBackPatch, op operation, int label);
	void backPatch(codeLine* lineToBackPatch, int label);

	void saveToFile();
};


#endif /* CODE_H_ */
