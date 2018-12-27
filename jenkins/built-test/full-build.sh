#!/bin/tcsh -f

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


source /opt/sphenix/core/bin/sphenix_setup.csh -n; 

mkdir -v ${WORKSPACE}/build;

cd ${WORKSPACE}/utilities/utils/rebuild/

env;

echo "Build step - build - start at " `pwd`;

./build.pl --stage 1 --source=${WORKSPACE} --version='new' --workdir=${WORKSPACE}/build;
set build_ret = $?;

echo "Build step - build - done";

if ($build_ret != 0) then
	echo "======================================================="
	echo "Failed build with return = ${build_ret}. Print end of log:";
	echo "======================================================="
    tail -n 100 ${WORKSPACE}/build/*/rebuild.log
	exit $build_ret;
endif

cd ${WORKSPACE};
ln -sbfv build/new/install

ls -lhvc;
