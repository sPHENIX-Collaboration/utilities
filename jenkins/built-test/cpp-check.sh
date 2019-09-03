#!/bin/tcsh


source /opt/sphenix/core/bin/sphenix_setup.csh -n; 

which cppcheck; 

if (-e  cppcheck-result.xml) then
	rsync -avl --remove-source-files cppcheck-result.xml cppcheck-result.xml.backup
endif

# cppcheck --enable=all --inconclusive --xml --xml-version=2 ./coresoftware >& cppcheck.xml 
# cppcheck -q --enable=warning --enable=style --enable=performance --platform=unix64 --inconclusive --xml --xml-version=2 -j16 -I $ROOTSYS/include/ ./coresoftware >& cppcheck.xml
# cppcheck -q --enable=warning --enable=style --enable=performance --platform=unix64 --inconclusive --xml --xml-version=2 -j16 --std=c++11 ./coresoftware > & cppcheck.xml
# cppcheck -q --enable=warning --enable=performance --platform=unix64 --inconclusive --xml --xml-version=2 -j 10 --std=c++11 ./coresoftware > & cppcheck-result.xml
cppcheck -q --inline-suppr  --enable=warning --enable=performance --platform=unix64 --inconclusive --xml --xml-version=2 -j 10 --std=c++11 ./coresoftware > & cppcheck-result.xml


ls -hvl $PWD/cppcheck-result.xml
wc -l cppcheck-result.xml

head -n 10 cppcheck-result.xml
