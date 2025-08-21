#!/bin/bash

name=test-tracking-reconstruction-prdf-QA-Gallery

cd $WORKSPACE/QA-gallery
pwd

cp -fv $WORKSPACE/macros/TrackingProduction/*prdf_reconstruction*.root* ./

ls -lhv


echo "======================================================="
echo "${name}: Reference";
echo "======================================================="

export qa_file_name_ref='None';
echo "use reference = ${use_reference}"
if [[ "${use_reference}" == "true" ]]; then
	ln -svfb ../reference
	
	export qa_file_name_ref=`/bin/ls -1 reference/*.root`
	
	echo "Reference file: with $qa_file_name_ref"
	ls -lhvc $qa_file_name_ref
	
fi

echo "======================================================="
echo "${name}: Initiating environment";
echo "======================================================="

export git_tag="$BUILD_TAG-${name}"

env | sort

git checkout -b update_${name}
git status
pwd
ls -lrt
source setup.sh 





