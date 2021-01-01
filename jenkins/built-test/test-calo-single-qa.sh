#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then	
	echo "Usage $0 particle_name pT_GeV number_jobs"
	exit 1;
fi

if [ -z "${system_config}" ]; then
	echo "Fatal error: Miss env system_config"
	exit 1;
fi

particle_ID=$1;
pT_GeV=$2;
number_jobs=$3; 

name=${particle_ID}_pT${pT_GeV}_Sum${number_jobs}

detector_name=sPHENIX
macro_name="Fun4All_G4_${detector_name}";


export OFFLINE_MAIN=$WORKSPACE/install

echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;

export ROOT_INCLUDE_PATH=${WORKSPACE}/macros/common:${ROOT_INCLUDE_PATH}

echo "======================================================="
echo "${name}: Env check";
echo "======================================================="
env;

echo "======================================================="
echo "cd macros/detectors/${detector_name}";
echo "======================================================="
cd macros/detectors/${detector_name}

pwd;
ls -lhc

id_number=1
while [ $id_number -le $number_jobs ]
do
	job_name=${particle_ID}_pT${pT_GeV}_${id_number}
  
	echo "======================================================="
	echo "${job_name}: Start test";
	echo "======================================================="
  
  	(/usr/bin/time -v root -b -q "Fun4All_G4_sPHENIX.C(20,"\"${particle_ID}\"",${pT_GeV},"\"G4sPHENIX_${job_name}\"")" && echo $? > exit_code_${id_number}.log ) &
	
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


#echo "======================================================="
#echo "${name}: go to QA directory";
#echo "======================================================="
#cd ../QA/calorimeter/
#pwd
#ls -lhv

echo "======================================================="
echo "${name}: Merging output to G4sPHENIX_${name}_qa.root";
echo "======================================================="

hadd -f G4sPHENIX_${name}_qa.root $WORKSPACE/macros/macros/g4simulations/G4sPHENIX_${particle_ID}_pT${pT_GeV}_*_qa.root

#echo "======================================================="
#echo "${name}: Drawing G4sPHENIX_${name}_qa.root";
#echo "======================================================="

#echo "Reference file: with reference/G4sPHENIX_${particle_ID}_pT${pT_GeV}_Sum*_qa.root"
#ls -lhvc reference/G4sPHENIX_${particle_ID}_pT${pT_GeV}_Sum*_qa.root

#echo "use reference = ${use_reference}"
#
#if (($? == 0) && (${use_reference} == "true")) then
#	
#	./QA_Draw_ALL.sh G4sPHENIX_${name}_qa.root reference/G4sPHENIX_${particle_ID}_pT${pT_GeV}_Sum*_qa.root
#
#else
#	
#	./QA_Draw_ALL.sh G4sPHENIX_${name}_qa.root
#	
#endif


