CC=g++
CCFLAGS = -Wall -pedantic -I ./inc/ -Ofast
all: compiler

compiler: flex bison ./tmp/SymbolTable.o ./inc/structures.h
	$(CC) ./tmp/lex.yy.c ./tmp/bison.tab.c ./tmp/SymbolTable.o $(CCFLAGS) -o compiler -lfl -Wno-write-strings

flex: ./src/flex.l bison
	flex -d --outfile=./tmp/lex.yy.c ./src/flex.l

bison: ./src/bison.y
	bison --defines=./inc/bison.tab.h --output=./tmp/bison.tab.c ./src/bison.y
	
./tmp/SymbolTable.o: ./inc/SymbolTable.h ./src/SymbolTable.cpp ./inc/structures.h
	$(CC) $(CCFLAGS) -c ./src/SymbolTable.cpp -o $@


clean: 
	rm -f ./tmp/lex.yy.c ./tmp/bison.tab.c ./inc/bison.tab.h ./tmp/SymbolTable.o ./tmp/*~