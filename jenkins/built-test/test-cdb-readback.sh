#!/bin/bash



test_cdb_file="test-cdb-readback.C"

cat >"$test_cdb_file" <<'EOF'
#include <CDBUtils.C>

void test_cdb_readback() {
    setGlobalTag("newcdbtag");

    cout << getCalibration("MBD_QFIT",20888) << endl;
    cout << getCalibration("MBD_QFIT",21199) << endl;
    cout << getCalibration("MBD_QFIT",21200) << endl;
    cout << getCalibration("MBD_QFIT",21518) << endl;
    cout << getCalibration("MBD_QFIT",21520) << endl;
    cout << getCalibration("MBD_QFIT",21560) << endl;
    cout << getCalibration("MBD_QFIT",23726) << endl;
    cout << getCalibration("MBD_QFIT",23727) << endl;
    cout << getCalibration("MBD_QFIT",23728) << endl;
    cout << getCalibration("MBD_QFIT",23735) << endl;
    cout << getCalibration("MBD_QFIT",23737) << endl;
    cout << getCalibration("MBD_QFIT",23738) << endl;
    cout << getCalibration("MBD_QFIT",23739) << endl;
    cout << getCalibration("MBD_QFIT",23740) << endl;
    cout << getCalibration("MBD_QFIT",23743) << endl;
    cout << getCalibration("MBD_QFIT",23745) << endl;
    cout << getCalibration("MBD_QFIT",23746) << endl;

}

EOF

ls -lhcv $test_cdb_file

echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;

export NOPAYLOADCLIENT_CONF=${OPT_SPHENIX}/etc/sPHENIX_newcdb_debug.json

echo "======================================================="
echo "Env check";
echo "======================================================="
env;

echo "======================================================="
echo "CDB check";
echo "======================================================="

which root.exe

root.exe -b -q "$test_cdb_file" 2>&1 | tee test_cdb_readback.log

root_status=${PIPESTATUS[0]}
if [ ${root_status} -ne 0 ]; then
  echo "ERROR: root.exe failed with exit code ${root_status}" >&2
  exit ${root_status}
fi



