#! tcsh -f

if ($#argv != 3) then
	
	echo "Usage $0 particle_name pT_GeV ID_Number"
	exit 1;
	
endif

set particle_ID = $1;
set pT_GeV = $2;
set id_number = $3; 

set job_name = ${particle_ID}_pT${pT_GeV}_${id_number}

source /opt/sphenix/core/bin/sphenix_setup.csh -n; 

setenv workRootPath `pwd`;
setenv PATH 		$WORKSPACE/install/bin:${PATH}
setenv LD_LIBRARY_PATH 	$WORKSPACE/install/lib:${LD_LIBRARY_PATH}
setenv CALIBRATIONROOT  $WORKSPACE/calibrations/

env;

cd macros/macros/g4simulations/

pwd;
ls -lhc



echo "======================================================="
echo "${job_name}: Start test";
echo "======================================================="


/usr/bin/time -v root -b -q root -b -q "Fun4All_G4_sPHENIX.C(10,"\"${particle_ID}\"",${pT_GeV},"\"${job_name}\"")" | & tee -a Fun4All_G4_sPHENIX_${job_name}.log;
set build_ret = $?;

echo "Build step - build - return $build_ret";

ls -lhcrt

if ($build_ret != 0) then
	echo "======================================================="
	echo "${job_name}: Failed build with return = ${build_ret}. ";
	echo "======================================================="
	exit $build_ret;
endif


echo "${job_name}: Build step - test - done";



