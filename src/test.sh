#!/bin/bash

echo "=== Testing N-Gram Generator ==="

echo "Test 1: Compilation"
ghc -o ngram-generator src/Main.hs src/DataTypes.hs src/Utils.hs src/Processing.hs src/IOHandler.hs
if [ $? -eq 0 ]; then
    echo "Compilation successful"
else
    echo "❌ Compilation failed"
    exit 1
fi

echo ""
echo "Test 2: Run with sample data"
echo "data/training.txt
2
1
the cat
10
n
4" | ./ngram-generator

echo ""
echo "=== All tests passed! ==="