#!/usr/bin/bash

set -e

echo "makin'"
make
echo "runnin'"
cd bin
./compiler.exe <input.txt
cd ..
