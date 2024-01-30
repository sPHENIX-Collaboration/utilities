#!/bin/bash

source /opt/sphenix/core/bin/sphenix_setup.sh -n; 

which clang-tidy; 

if test -f clang-tidy-result.txt; then
  mv -fv clang-tidy-result.txt clang-tidy-result.txt.backup
fi

shopt -s globstar
clang-tidy ./coresoftware/**/*.cc ./coresoftware/**/*.cpp -- -Wall -Werror -Wshadow -std=c++17 -I$OFFLINE_MAIN/include -isystem$ROOTSYS/include -I$G4_MAIN/include -I$G4_MAIN/include/Geant4 -I$OPT_SPHENIX/include > clang-tidy-result.txt

ls -hvl $PWD/clang-tidy-result.txt
wc -l clang-tidy-result.txt
head -n 10 clang-tidy-result.txt
