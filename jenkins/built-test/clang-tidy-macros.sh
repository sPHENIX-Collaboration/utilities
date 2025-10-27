#!/bin/bash

echo "-----------------------------------"
echo " Start header installation "
echo "-----------------------------------"

echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n new;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n new;

echo "-----------------------------------"
echo " Clang Tidy Check "
echo "-----------------------------------"

export OFFLINE_MAIN=$WORKSPACE/install
echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n new;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n new;


which clang-tidy; 
env;

cd ${WORKSPACE}
pwd
ls -lhcv

if test -f clang-tidy-result.txt; then
  mv -fv clang-tidy-result.txt clang-tidy-result.txt.backup
fi

shopt -s globstar
# clang-tidy ./macros/**/*.cc ./macros/**/*.cpp ./macros/**/*.C -- -Wall -Werror -Wshadow -std=c++20 -Wno-dangling -isystem$WORKSPACE/macros/common  -isystem$OFFLINE_MAIN/include -isystem$ROOTSYS/include -isystem$G4_MAIN/include -isystem$G4_MAIN/include/Geant4  -isystem$OPT_SPHENIX/include -DHomogeneousField -DEVTGEN_HEPMC3 -DRAVE -DRaveDllExport= > clang-tidy-result.txt
clang-tidy ./macros/**/*.cc ./macros/**/*.cpp ./macros/**/*.C -- -Wall -Werror -Wshadow -std=c++20 -Wno-dangling -isystem$WORKSPACE/macros/common -isystem$OFFLINE_MAIN/include -isystem$ROOTSYS/include -isystem$G4_MAIN/include -isystem$G4_MAIN/include/Geant4 -isystem$OPT_SPHENIX/include -isystem$OFFLINE_MAIN/rootmacros -DHomogeneousField -DEVTGEN_HEPMC3 -DRAVE -DRaveDllExport=

ls -hvl $PWD/clang-tidy-result.txt
wc -l clang-tidy-result.txt
head -n 10 clang-tidy-result.txt
