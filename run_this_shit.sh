#!/usr/bin/bash

set -e

echo "bisonin'"
bison -d bison.y
echo "flexin'"
flex -d flex.l
echo "compilin'"
g++ lex.yy.c bison.tab.c -o compiler -lfl -Wno-write-strings
echo "runnin'"
./compiler.exe <input.txt >output.txt
