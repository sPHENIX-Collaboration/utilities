#!/bin/csh -f

# create dumb shell script to call build.pl inside container
echo "#\!/bin/csh -f" > scan-build.csh
echo "source /opt/sphenix/core/bin/sphenix_setup.csh -n" >> scan-build.csh
echo "build.pl --scanbuild --phenixinstall --version='scan'" >> scan-build.csh
chmod +x scan-build.csh

set dir=$PWD
singularity exec -B /cvmfs/sphenix.sdcc.bnl.gov/x8664_sl7/patches/hashtable_policy.h:/usr/include/c++/4.8.2/bits/hashtable_policy.h -B /home -B /gpfs -B /sphenix -B /direct/phenix+WWW -B /phenix /cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg $dir/scan-build.csh
