CC=g++
CCFLAGS = -Wall -pedantic -I ./inc/ -Ofast
all: compiler

compiler: flex bison ./tmp/SymbolTable.o ./tmp/Code.o ./tmp/structures.o
	$(CC) ./tmp/lex.yy.c ./tmp/bison.tab.c ./tmp/SymbolTable.o ./tmp/Code.o ./tmp/structures.o $(CCFLAGS) -o ./bin/compiler -lfl -Wno-write-strings

flex: ./src/flex.l bison
	flex -d --outfile=./tmp/lex.yy.c ./src/flex.l

bison: ./src/bison.y
	bison --report=all -t --defines=./inc/bison.tab.h --output=./tmp/bison.tab.c ./src/bison.y
	
./tmp/SymbolTable.o: ./inc/SymbolTable.h ./src/SymbolTable.cpp ./tmp/structures.o
	$(CC) $(CCFLAGS) -c ./src/SymbolTable.cpp -o $@

./tmp/Code.o: ./inc/Code.h ./src/Code.cpp ./tmp/structures.o
	$(CC) $(CCFLAGS) -c ./src/Code.cpp -o $@

./tmp/structures.o:	./inc/structures.h ./src/structures.cpp
	$(CC) $(CCFLAGS) -c ./src/structures.cpp -o $@

clean: 
	rm -f ./tmp/lex.yy.c ./tmp/bison.tab.c ./inc/bison.tab.h ./tmp/SymbolTable.o ./tmp/structures.o ./tmp/*~