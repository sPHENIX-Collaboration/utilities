#!/bin/bash

echo "-----------------------------------"
echo " Start header installation "
echo "-----------------------------------"

echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n new;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n new;

mkdir -v ${WORKSPACE}/build;

cd ${WORKSPACE}/utilities/utils/rebuild/
# cat ${WORKSPACE}/utilities/jenkins/built-test/full-build.extra_packages.txt >> packages.txt
./build.pl --stage 1 --to_stage=2 --source=${WORKSPACE} --workdir=${WORKSPACE}/build;

cd ${WORKSPACE}
ln -sbfv build/new/install.1 ./install
ls -lhcv

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
# clang-tidy ./coresoftware/**/*.cc ./coresoftware/**/*.cpp -- -Wall -Werror -Wshadow -std=c++20 -Wno-dangling -isystem$OFFLINE_MAIN/include -isystem$ROOTSYS/include -isystem$G4_MAIN/include -isystem$G4_MAIN/include/Geant4  -isystem$OPT_SPHENIX/include -DHomogeneousField -DEVTGEN_HEPMC3 -DRAVE -DRaveDllExport= > clang-tidy-result.txt
find ./coresoftware -type f \( -name '*.cc' -o -name '*.cpp' \) -print0 | \
  xargs -0 -n 1 -P 32 \
  clang-tidy -- -Wall -Werror -Wshadow -std=c++20 -Wno-dangling \
    -isystem$OFFLINE_MAIN/include -isystem$ROOTSYS/include \
    -isystem$G4_MAIN/include -isystem$G4_MAIN/include/Geant4 \
    -isystem$OPT_SPHENIX/include -DHomogeneousField \
    -DEVTGEN_HEPMC3 -DRAVE -DRaveDllExport= \
    > clang-tidy-result.txt

ls -hvl $PWD/clang-tidy-result.txt
wc -l clang-tidy-result.txt
head -n 10 clang-tidy-result.txt
