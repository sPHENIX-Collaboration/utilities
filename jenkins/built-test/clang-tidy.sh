#!/bin/bash



echo "-----------------------------------"
echo " Start header installation "
echo "-----------------------------------"

source /opt/sphenix/core/bin/sphenix_setup.sh -n;
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
source /opt/sphenix/core/bin/sphenix_setup.sh; 

which clang-tidy; 
env;

cd ${WORKSPACE}
pwd
ls -lhcv

if test -f clang-tidy-result.txt; then
  mv -fv clang-tidy-result.txt clang-tidy-result.txt.backup
fi

shopt -s globstar
clang-tidy ./coresoftware/**/*.cc ./coresoftware/**/*.cpp -- -Wall -Werror -Wshadow -std=c++17 -I$OFFLINE_MAIN/include -isystem$ROOTSYS/include -I$G4_MAIN/include -I$G4_MAIN/include/Geant4 -I$OPT_SPHENIX/include > clang-tidy-result.txt

ls -hvl $PWD/clang-tidy-result.txt
wc -l clang-tidy-result.txt
head -n 10 clang-tidy-result.txt
