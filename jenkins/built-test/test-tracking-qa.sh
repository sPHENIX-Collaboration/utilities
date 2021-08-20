#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then	
	echo "Usage $0 num_event number_jobs"
	exit 1;
fi

if [ -z "${system_config}" ]; then
	echo "Fatal error: Miss env system_config"
	exit 1;
fi

if [ -z "${build_type}" ]; then
	echo "Fatal error: Miss env build_type"
	exit 1;
fi


num_event=$1;
number_jobs=$2;

name=test-tracking_Event${num_event}_Sum${number_jobs}

detector_name=sPHENIX
macro_name="Fun4All_G4_${detector_name}";


export OFFLINE_MAIN=$WORKSPACE/install
# export CALIBRATIONROOT=$WORKSPACE/calibrations # handle via OFFLINE_MAIN
# note this is not using -n parameter to overwrite OFFLINE_MAIN
echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;

export ROOT_INCLUDE_PATH=${WORKSPACE}/macros/common:${ROOT_INCLUDE_PATH}

echo "======================================================="
echo "${name}: Env check";
echo "======================================================="
env;

macro_dir=$WORKSPACE/macros/detectors/${detector_name}
echo "======================================================="
echo "cd ${macro_dir}";
echo "======================================================="
cd ${macro_dir}

pwd;
ls -lhc



id_number=1
while [ $id_number -le $number_jobs ]
do
	job_name=job_${id_number}
  
	echo "======================================================="
	echo "${job_name}: Start test";
	echo "======================================================="
  
  	(/usr/bin/time -v root -b -q "Fun4All_G4_sPHENIX.C(${num_event},"\"NullInput\"","\"G4sPHENIX_${job_name}\"")" && echo $? > exit_code_${id_number}.log ) 2>&1 | tee G4sPHENIX_${job_name}.log | (head; tail -n 100)  &
	
  	sleep 1s;
	((id_number++))
done

wait;

id_number=1

while [ $id_number -le $number_jobs ]
do
	build_ret=`cat exit_code_${id_number}.log`;

	echo "Build step - build - return $build_ret";
	
	
	if [ $build_ret -ne 0 ]; then
		echo "======================================================="
		echo "Job index ${id_number}: Failed build with return = ${build_ret}. ";
		echo "======================================================="
		exit $build_ret;
	fi
	
	((id_number++))
done

ls -lhcrt


echo "======================================================="
echo "${name}: go to QA directory";
echo "======================================================="

if [ -f "README.md" ]; then
    cp -fv README.md $WORKSPACE/QA-gallery/Fun4All-macros-README.md
else
	echo "missing README.md at " $PWD
fi

cd $WORKSPACE/QA-gallery
pwd
ls -lhv

export qa_file_name_new=G4sPHENIX_${name}_qa.root
echo "======================================================="
echo "${name}: Merging output to $qa_file_name_new";
echo "======================================================="

echo hadd -f $qa_file_name_new ${macro_dir}/G4sPHENIX_job*_qa.root
hadd -f $qa_file_name_new ${macro_dir}/G4sPHENIX_job*_qa.root


echo "======================================================="
echo "${name}: Reference";
echo "======================================================="

export qa_file_name_ref='None';
echo "use reference = ${use_reference}"
if [ ${use_reference} ]; then
	ln -svfb ../reference
	
	export qa_file_name_ref=`/bin/ls -1 reference/G4sPHENIX_*Sum*_qa.root`
	
	echo "Reference file: with $qa_file_name_ref"
	ls -lhvc $qa_file_name_ref
	
fi




# echo "======================================================="
# echo fake fast runs !! Remove before release!
# echo "======================================================="
# ln -svfb $qa_file_name_ref $qa_file_name_new

echo "======================================================="
echo "${name}: Initiating environment";
echo "======================================================="

export git_tag="$BUILD_TAG-${name}"

git checkout -b update_${name}
git status

sh setup.sh 

source ./env/bin/activate

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
	
	summary="* [:bar_chart: ${filename}](https://nbviewer.jupyter.org/github/sPHENIX-Collaboration/QA-gallery/blob/${git_tag}/${nbname})"
	
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

