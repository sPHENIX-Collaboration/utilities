#! tcsh -f

if ($#argv != 3) then
	
	echo "Usage $0 Fun4All_G4_sPHENIX number_event run_valgrind"
	exit 1;
	
endif

set macro_name = $1;
set number_event = $2;
set run_valgrind = $3;


# source /opt/sphenix/core/bin/sphenix_setup.csh -n; 

# setenv workRootPath `pwd`;
# setenv PATH 		$WORKSPACE/install/bin:${PATH}
# setenv LD_LIBRARY_PATH 	$WORKSPACE/install/lib:${LD_LIBRARY_PATH}
# setenv CALIBRATIONROOT  $WORKSPACE/calibrations/

setenv OFFLINE_MAIN $WORKSPACE/install
setenv ONLINE_MAIN $WORKSPACE/install
setenv CALIBRATIONROOT  $WORKSPACE/calibrations

source /opt/sphenix/core/bin/sphenix_setup.csh;
source /opt/sphenix/core/bin/setup_root6.csh ${WORKSPACE}/install/

echo "======================================================="
echo "env check";
echo "======================================================="

env;

cd macros/macros/g4simulations/

pwd;
ls -lhc


set valgrind_prefix = "";

if ($run_valgrind > 0) then
	
	set valgrind_sup = '';

	if (-e $ROOTSYS/root.supp) then
	    set valgrind_sup = "--suppressions=$ROOTSYS/root.supp";
	endif	
	
	# set valgrind_prefix = "valgrind -v  --num-callers=30 --leak-check=full --error-limit=no --log-file=${macro_name}.valgrind $valgrind_sup --xml=yes --xml-file=${macro_name}.valgrind.xml --leak-resolution=high"
	set valgrind_prefix = "valgrind -v  --num-callers=30 --leak-check=full --error-limit=no --log-file=${macro_name}.valgrind $valgrind_sup  --leak-resolution=high"
	
	which valgrind
	echo "valgrind_prefix = ${valgrind_prefix}"
	
endif

echo "======================================================="
echo "Start test";
echo "======================================================="

# Test case to produce memory error
# echo '{int ret = gSystem->Load("libg4bbc.so"); cout <<"Load libg4detectors = "<<ret<<endl;assert(ret == 0);BbcVertexFastSimReco* bbcvertex = new BbcVertexFastSimReco();BbcVertexFastSimReco* bbcvertex = new BbcVertexFastSimReco();int a[2] = {0}; a[3] = 1;exit(0);}' > test.C

/usr/bin/time -v ${valgrind_prefix} root.exe -b -q "${macro_name}.C(${number_event})" | & tee -a ${macro_name}.log;

set build_ret = $?;

ls -lhcrt

echo "Build step - build - return $build_ret";

if ($build_ret != 0) then
	echo "======================================================="
	echo "Failed run with return = ${build_ret}. ";
	echo "======================================================="
	
	if ($run_valgrind == 0) then
		exit $build_ret;
	endif
endif

echo "Build step - test - done";




