#!/bin/tcsh

source /opt/sphenix/core/bin/sphenix_setup.csh -n; 

which clang-tidy; 

if (-e  clang-tidy-result.xml) then
	rsync -avl --remove-source-files clang-tidy-result.xml clang-tidy-result.xml.backup
endif

# cppcheck -q --inline-suppr  --enable=warning --enable=performance --platform=unix64 --inconclusive --xml --xml-version=2 -j 10 --std=c++20 ./coresoftware > & cppcheck-result.xml
clang-tidy *.cc -- -Wall -Werror -Wshadow -std=c++17 -I$OFFLINE_MAIN/include -isystem$ROOTSYS/include -I$G4_MAIN/include -I$G4_MAIN/include/Geant4 -I$OPT_SPHENIX/include -o clang-tidy-result.txt

ls -hvl $PWD/clang-tidy-result.txt
wc -l clang-tidy-result.txt
head -n 10 clang-tidy-result.txt
