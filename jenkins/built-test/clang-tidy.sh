#!/bin/tcsh

source /opt/sphenix/core/bin/sphenix_setup.csh -n; 

which clang-tidy; 

if (-e  clang-tidy-result.txt) then
	rsync -avl --remove-source-files clang-tidy-result.txt clang-tidy-result.txt.backup
endif

run-clang-tidy ./coresoftware -- -Wall -Werror -Wshadow -std=c++17 -I$OFFLINE_MAIN/include -isystem$ROOTSYS/include -I$G4_MAIN/include -I$G4_MAIN/include/Geant4 -I$OPT_SPHENIX/include -o clang-tidy-result.txt

ls -hvl $PWD/clang-tidy-result.txt
wc -l clang-tidy-result.txt
head -n 10 clang-tidy-result.txt
