#! /bin/tcsh -f

source /opt/phenix/bin/phenix_setup.csh -n
rm -rf /home/phnxbld/doxygen_sPHENIX
mkdir -p /home/phnxbld/doxygen_sPHENIX
cd /home/phnxbld/doxygen_sPHENIX
git clone https://github.com/sPHENIX-Collaboration/utilities.git 
mv utilities/utils ./
cd utils/rebuild 
run_doxygen.pl >& doxy.log
