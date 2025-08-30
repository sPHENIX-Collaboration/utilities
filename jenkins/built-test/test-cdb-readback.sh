#!/bin/bash



output_file="test_cdb-readback.C"

cat >"$output_file" <<'EOF'
#include <CDBUtils.C>

void test_cdb_readback() {
    setGlobalTag("newcdbtag");

    cout << getCalibration("MBD_QFIT",20888) << endl;
    cout << getCalibration("MBD_QFIT",21199) << endl;
    cout << getCalibration("MBD_QFIT",21200) << endl;
    cout << getCalibration("MBD_QFIT",21518) << endl;
    cout << getCalibration("MBD_QFIT",21520) << endl;
    cout << getCalibration("MBD_QFIT",21560) << endl;
    cout << getCalibration("MBD_QFIT",21561) << endl;
    cout << getCalibration("MBD_QFIT",21562) << endl;
    cout << getCalibration("MBD_QFIT",21564) << endl;
    cout << getCalibration("MBD_QFIT",21565) << endl;
    cout << getCalibration("MBD_QFIT",21567) << endl;
    cout << getCalibration("MBD_QFIT",21568) << endl;
    cout << getCalibration("MBD_QFIT",21578) << endl;
    cout << getCalibration("MBD_QFIT",21579) << endl;
    cout << getCalibration("MBD_QFIT",21580) << endl;
    cout << getCalibration("MBD_QFIT",21581) << endl;
    cout << getCalibration("MBD_QFIT",21584) << endl;
    cout << getCalibration("MBD_QFIT",21587) << endl;
    cout << getCalibration("MBD_QFIT",21589) << endl;
    cout << getCalibration("MBD_QFIT",21594) << endl;
    cout << getCalibration("MBD_QFIT",21598) << endl;
    cout << getCalibration("MBD_QFIT",21599) << endl;
    cout << getCalibration("MBD_QFIT",21608) << endl;
    cout << getCalibration("MBD_QFIT",21609) << endl;
    cout << getCalibration("MBD_QFIT",21615) << endl;
    cout << getCalibration("MBD_QFIT",21616) << endl;
    cout << getCalibration("MBD_QFIT",21626) << endl;
    cout << getCalibration("MBD_QFIT",21627) << endl;
    cout << getCalibration("MBD_QFIT",21663) << endl;
    cout << getCalibration("MBD_QFIT",21665) << endl;
    cout << getCalibration("MBD_QFIT",21674) << endl;
    cout << getCalibration("MBD_QFIT",21678) << endl;
    cout << getCalibration("MBD_QFIT",21679) << endl;
    cout << getCalibration("MBD_QFIT",21681) << endl;
    cout << getCalibration("MBD_QFIT",21682) << endl;
    cout << getCalibration("MBD_QFIT",21683) << endl;
    cout << getCalibration("MBD_QFIT",21703) << endl;
    cout << getCalibration("MBD_QFIT",21704) << endl;
    cout << getCalibration("MBD_QFIT",21705) << endl;
    cout << getCalibration("MBD_QFIT",21707) << endl;
    cout << getCalibration("MBD_QFIT",21709) << endl;
    cout << getCalibration("MBD_QFIT",21719) << endl;
    cout << getCalibration("MBD_QFIT",21733) << endl;
    cout << getCalibration("MBD_QFIT",21739) << endl;
    cout << getCalibration("MBD_QFIT",21740) << endl;
    cout << getCalibration("MBD_QFIT",21744) << endl;
    cout << getCalibration("MBD_QFIT",21745) << endl;
    cout << getCalibration("MBD_QFIT",21747) << endl;
    cout << getCalibration("MBD_QFIT",21748) << endl;
    cout << getCalibration("MBD_QFIT",21750) << endl;
    cout << getCalibration("MBD_QFIT",21751) << endl;
    cout << getCalibration("MBD_QFIT",21754) << endl;
    cout << getCalibration("MBD_QFIT",21769) << endl;
    cout << getCalibration("MBD_QFIT",21770) << endl;
    cout << getCalibration("MBD_QFIT",21772) << endl;
    cout << getCalibration("MBD_QFIT",21774) << endl;
    cout << getCalibration("MBD_QFIT",21776) << endl;
    cout << getCalibration("MBD_QFIT",21778) << endl;
    cout << getCalibration("MBD_QFIT",21780) << endl;
    cout << getCalibration("MBD_QFIT",21782) << endl;
    cout << getCalibration("MBD_QFIT",21783) << endl;
    cout << getCalibration("MBD_QFIT",21785) << endl;
    cout << getCalibration("MBD_QFIT",21787) << endl;
    cout << getCalibration("MBD_QFIT",21788) << endl;
    cout << getCalibration("MBD_QFIT",21792) << endl;
    cout << getCalibration("MBD_QFIT",21793) << endl;
    cout << getCalibration("MBD_QFIT",21795) << endl;
    cout << getCalibration("MBD_QFIT",21796) << endl;
    cout << getCalibration("MBD_QFIT",21798) << endl;
    cout << getCalibration("MBD_QFIT",21813) << endl;
    cout << getCalibration("MBD_QFIT",21889) << endl;
    cout << getCalibration("MBD_QFIT",21891) << endl;
    cout << getCalibration("MBD_QFIT",22026) << endl;
    cout << getCalibration("MBD_QFIT",22027) << endl;
    cout << getCalibration("MBD_QFIT",22033) << endl;
    cout << getCalibration("MBD_QFIT",22034) << endl;
    cout << getCalibration("MBD_QFIT",22037) << endl;
    cout << getCalibration("MBD_QFIT",22046) << endl;
    cout << getCalibration("MBD_QFIT",22911) << endl;
    cout << getCalibration("MBD_QFIT",22911) << endl;
    cout << getCalibration("MBD_QFIT",22946) << endl;
    cout << getCalibration("MBD_QFIT",22948) << endl;
    cout << getCalibration("MBD_QFIT",22949) << endl;
    cout << getCalibration("MBD_QFIT",22950) << endl;
    cout << getCalibration("MBD_QFIT",22951) << endl;
    cout << getCalibration("MBD_QFIT",22979) << endl;
    cout << getCalibration("MBD_QFIT",22982) << endl;
    cout << getCalibration("MBD_QFIT",23020) << endl;
    cout << getCalibration("MBD_QFIT",23671) << endl;
    cout << getCalibration("MBD_QFIT",23672) << endl;
    cout << getCalibration("MBD_QFIT",23676) << endl;
    cout << getCalibration("MBD_QFIT",23681) << endl;
    cout << getCalibration("MBD_QFIT",23682) << endl;
    cout << getCalibration("MBD_QFIT",23687) << endl;
    cout << getCalibration("MBD_QFIT",23690) << endl;
    cout << getCalibration("MBD_QFIT",23693) << endl;
    cout << getCalibration("MBD_QFIT",23694) << endl;
    cout << getCalibration("MBD_QFIT",23695) << endl;
    cout << getCalibration("MBD_QFIT",23696) << endl;
    cout << getCalibration("MBD_QFIT",23697) << endl;
    cout << getCalibration("MBD_QFIT",23699) << endl;
    cout << getCalibration("MBD_QFIT",23702) << endl;
    cout << getCalibration("MBD_QFIT",23714) << endl;
    cout << getCalibration("MBD_QFIT",23718) << endl;
    cout << getCalibration("MBD_QFIT",23721) << endl;
    cout << getCalibration("MBD_QFIT",23722) << endl;
    cout << getCalibration("MBD_QFIT",23723) << endl;
    cout << getCalibration("MBD_QFIT",23724) << endl;
    cout << getCalibration("MBD_QFIT",23725) << endl;
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

root.exe -b -q 'test_cdb_readback.C' | tee test_cdb_readback.log

root_status=${PIPESTATUS[0]}
if [ ${root_status} -ne 0 ]; then
  echo "ERROR: root.exe failed with exit code ${root_status}" >&2
  exit ${root_status}
fi



