#!/bin/csh -f

# create dumb shell script to call build.pl inside container
echo "#\!/bin/csh -f" > clang_includecheck.csh
echo "source /opt/sphenix/core/bin/sphenix_setup.csh -n clang" >> clang_includecheck.csh
echo "build.pl --includecheck --version='includecheck'" >> clang_includecheck.csh
chmod +x clang_includecheck.csh

set dir=$PWD
singularity exec -B /cvmfs/sphenix.sdcc.bnl.gov/x8664_sl7/patches/hashtable_policy.h:/usr/include/c++/4.8.2/bits/hashtable_policy.h -B /home -B /gpfs -B /sphenix /cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg $dir/clang_includecheck.csh
