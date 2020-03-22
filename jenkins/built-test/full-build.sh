#!/usr/bin/env bash

# source /afs/rhic.bnl.gov/opt/sphenix/core/bin/sphenix_setup.csh -n 
# &&  set path = ($HOME/sPHENIX/ccache/bin $HOME/distcc/bin $path) 
# && setenv CCACHE_DIR /home/phnxbld/.sphenixccache 
# && kinit -k -t $HOME/.private/phnxbld.keytab phnxbld 
# && aklog &&  rm -rf /home/phnxbld/sPHENIX/new 
# && rm -rf /home/phnxbld/sPHENIX/newbuild 
# && mkdir -p /home/phnxbld/sPHENIX/newbuild
# && cd /home/phnxbld/sPHENIX/newbuild && 
# git clone https://github.com/sPHENIX-Collaboration/utilities ./  >& $HOME/sphenixbld.log 
# && cd utils/rebuild 
# && ./build.pl --phenixinstall --notify --afs

if [ -z "${system_config}" ]; then
	echo "Fatal error: Miss env system_config"
	exit 1;
fi
if [ -z "$build_type" ]; then	
	echo "Fatal error: Miss env build_type"
	exit 1;
fi

echo "Build type ${system_config} - ${build_type}"

echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n $build_type;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n $build_type;
export HOST=`hostname`; # as build macro seeks $HOST

mkdir -v ${WORKSPACE}/build;

cd ${WORKSPACE}/utilities/utils/rebuild/
cat ${WORKSPACE}/utilities/jenkins/built-test/full-build.extra_packages.txt >> packages.txt


export HOST=`hostname`
echo "env check";

env;

echo "Build step - build - start at " `pwd`;

build_ret=0;
if [[ ${build_type} == 'clang' ]]; then
	echo  	"./build.pl --stage 1 --source=${WORKSPACE} --version="${build_type}" --sysname=${system_config} --${build_type} --workdir=${WORKSPACE}/build;"
 	./build.pl --stage 1 --source=${WORKSPACE} --version="${build_type}" --sysname=${system_config} --${build_type} --workdir=${WORKSPACE}/build;
	build_ret=$?;
elif [[ ${build_type} == 'scan' ]]; then
	echo  	"./build.pl --stage 1 --source=${WORKSPACE} --version="${build_type}" --sysname=${system_config} --scanbuild --workdir=${WORKSPACE}/build;"
 	./build.pl --stage 1 --source=${WORKSPACE} --version="${build_type}" --sysname=${system_config} --scanbuild --workdir=${WORKSPACE}/build;
	build_ret=$?;
else
	echo "./build.pl --stage 1 --source=${WORKSPACE} --version="${build_type}" --sysname=${system_config} --workdir=${WORKSPACE}/build;"
	./build.pl --stage 1 --source=${WORKSPACE} --version="${build_type}" --sysname=${system_config} --workdir=${WORKSPACE}/build;
	build_ret=$?;
fi

echo "Build step - build - done";

if (( $build_ret != 0 )); then
	echo "======================================================="
	echo "Failed ${build_type} build with return = ${build_ret}. Print end of log:";
	echo "======================================================="
    tail -n 100 ${WORKSPACE}/build/*/rebuild.log
	exit $build_ret;
fi

cd ${WORKSPACE};
ln -sbfv build/${build_type}/install ./

ls -lhvc;
