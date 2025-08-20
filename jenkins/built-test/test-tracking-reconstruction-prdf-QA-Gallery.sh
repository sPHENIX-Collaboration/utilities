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

echo "======================================================="
echo "${name}: Drawing G4sPHENIX_${name}_qa.root";
echo "================================================"

notebooks=`/bin/ls -1 *.ipynb`

while IFS= read -r nbname; 
do 
	echo "Processing $nbname ..."; 
	
	# nbname=QA-calorimeter.ipynb 
	sh run.sh ${nbname}
	
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
