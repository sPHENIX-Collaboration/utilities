#! tcsh -f

if ($#argv != 3) then
	
	echo "Usage $0 particle_name pT_GeV number_jobs"
	exit 1;
	
endif

set particle_ID = $1;
set pT_GeV = $2;
set number_jobs = $3; 

set name = ${particle_ID}_pT${pT_GeV}_Sum${number_jobs}

setenv OFFLINE_MAIN $WORKSPACE/install
setenv ONLINE_MAIN $WORKSPACE/install
setenv CALIBRATIONROOT  $WORKSPACE/calibrations

source /opt/sphenix/core/bin/sphenix_setup.csh; 
source /opt/sphenix/core/bin/setup_root6.csh ${WORKSPACE}/install/

# setenv PATH 		$WORKSPACE/install/bin:${PATH}
# setenv LD_LIBRARY_PATH 	$WORKSPACE/install/lib:${LD_LIBRARY_PATH}

echo "======================================================="
echo "${name}: Env check";
echo "======================================================="
env;

cd macros/macros/g4simulations/

#ln -svfb $WORKSPACE//coresoftware/offline/QA/macros/* ./

pwd;
ls -lhc

set id_number = 1
while ( $id_number <= $number_jobs )
   set job_name = ${particle_ID}_pT${pT_GeV}_${id_number}
   
   	echo "======================================================="
	echo "${job_name}: Start test";
	echo "======================================================="

	(/usr/bin/time -v root -b -q "Fun4All_G4_sPHENIX.C(20,"\"${particle_ID}\"",${pT_GeV},"\"G4sPHENIX_${job_name}\"")" | & tee -a Fun4All_G4_sPHENIX_${job_name}.log ; echo $? > exit_code_${id_number}.log ) &;
   
   sleep 1s;
   
   @ id_number++
end

wait;

set id_number = 1
while ( $id_number <= $number_jobs )
	set build_ret = `cat exit_code_${id_number}.log`;

	echo "Build step - build - return $build_ret";
	
	if ($build_ret != 0) then
		echo "======================================================="
		echo "Job index ${id_number}: Failed build with return = ${build_ret}. ";
		echo "======================================================="
		exit $build_ret;
	endif
   @ id_number++
end

ls -lhcrt


echo "======================================================="
echo "${name}: go to QA directory";
echo "======================================================="
cd ../QA/calorimeter/
pwd
ls -lhv

echo "======================================================="
echo "${name}: Merging output to G4sPHENIX_${name}_qa.root";
echo "======================================================="

hadd -f G4sPHENIX_${name}_qa.root $WORKSPACE/macros/macros/g4simulations/G4sPHENIX_${particle_ID}_pT${pT_GeV}_*_qa.root

echo "======================================================="
echo "${name}: Drawing G4sPHENIX_${name}_qa.root";
echo "======================================================="

echo "Reference file: with reference/G4sPHENIX_${particle_ID}_pT${pT_GeV}_Sum*_qa.root"
ls -lhvc reference/G4sPHENIX_${particle_ID}_pT${pT_GeV}_Sum*_qa.root

echo "use reference = ${use_reference}"

if (($? == 0) && (${use_reference} == "true")) then
	
	./QA_Draw_ALL.sh G4sPHENIX_${name}_qa.root reference/G4sPHENIX_${particle_ID}_pT${pT_GeV}_Sum*_qa.root

else
	
	./QA_Draw_ALL.sh G4sPHENIX_${name}_qa.root
	
endif


