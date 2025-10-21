#!/bin/bash

if [ -z "${build_type}" ]; then
	echo "Fatal error: Miss env build_type"
	exit 1;
fi

name=test-tracking-reconstruction-prdf-QA-Gallery


cd $WORKSPACE/QA-gallery
pwd

cp -fv $WORKSPACE/macros/TrackingProduction/*prdf_reconstruction*.root* ./
export qa_file_name_new=$WORKSPACE/macros/TrackingProduction/prdf_reconstruction53877_qa.root
ls -lhv

echo "environment before "
env | sort
echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;
echo "======================================================="
echo "${name}: Reference";
echo "======================================================="

ln -svfb ../reference
	
export qa_file_name_ref=`/bin/ls -1 reference/*.root`
	
echo "Reference file: with $qa_file_name_ref"
ls -lhvc $qa_file_name_ref
	

echo "======================================================="
echo "${name}: Initiating environment";
echo "======================================================="

export git_tag="$BUILD_TAG-${name}"

env | sort

git checkout -b update_${name}
git status
pwd
ls -lrt
source $(pwd)/setup.sh 

echo "======================================================="
echo "${name}: Drawing ${name} QA";
echo "================================================"

notebooks=`/bin/ls -1 *.ipynb`

while IFS= read -r nbname; 
do 
	echo "Processing $nbname ..."; 
	
	# nbname=QA-calorimeter.ipynb 
	bash run.sh ${nbname}
	
	build_ret=$?
	if [ $build_ret -ne 0 ]; then
		echo "======================================================="
		echo "${nbname}: Failed build with return = ${build_ret}. ";
		echo "======================================================="
		exit $build_ret;
	fi	
done <<< "$notebooks"



echo "======================================================="
echo "${name}: push for publication";
echo "======================================================="

git status

git commit -am "Processing tracking QA at $JOB_URL"
git tag -a $git_tag -m "Build by sPHENIX Jenkins CI at $JOB_URL"
git push origin $git_tag


echo "======================================================="
echo "${name}: build Markdown reports";
echo "======================================================="

while IFS= read -r nbname; 
do 
	echo "Processing $nbname ..."; 
	
	# nbname=QA-calorimeter.ipynb 
	filename=`basename ${nbname} .ipynb`
	
	summary="* [:bar_chart: ${filename}](https://nbviewer.sphenix.bnl.gov/github/sPHENIX-Collaboration/QA-gallery/blob/${git_tag}/${nbname})"
	
	if [ -f "${filename}.txt" ]; then
		
		notebook_summary=$( cat ${filename}.txt )
		echo "Note book summary, ${filename}.txt : $notebook_summary"
		
    	summary="$summary : $notebook_summary"
	fi
	
	echo "$summary" > report-${nbname}.md

	ls -lhvc report-${nbname}.md
	cat report-${nbname}.md

	# mv -fv ${filename}.html ${nbname}.html
	
done <<< "$notebooks"
