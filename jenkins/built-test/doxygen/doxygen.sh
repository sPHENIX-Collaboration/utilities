#!/bin/bash

pwd;

env;

echo "-------- source setup ---------"
source /opt/sphenix/core/bin/sphenix_setup.sh -n

env;

echo "doxygen at " `which doxygen`
echo "dot at " `which dot`


echo "-------- Doxyfile additional setup ---------"
echo "CVS_STRIP_FROM_PATH = " `pwd`/ | tee -a Doxyfile
echo "INPUT                  = " doxygen_mainpage.h `/bin/ls -d */` | tee -a Doxyfile

echo "-------- start doxygen ---------"

doxygen Doxyfile >& doxygen.log
build_ret=$?;

echo "Build step - build - done. return = ${build_ret}";

if (( $build_ret != 0 )); then
	echo "======================================================="
	echo "Failed doxygen build with return = ${build_ret}. Print end of log:";
	echo "======================================================="
    tail -n 100 *.log
	exit $build_ret;
fi

echo "-------- publishing ---------"

cd html/

pwd
ll

git init
git checkout -b gh-pages
git status
git add .
git commit -am "doxygen build at `date`"

git remote add origin git@github.com:sPHENIX-Collaboration/doxygen.git
git push -f origin gh-pages

