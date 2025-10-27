#!/bin/bash

echo "-----------------------------------"
echo " Start header installation "
echo "-----------------------------------"

echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n new;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n new;

mkdir -v ${WORKSPACE}/build;

cd ${WORKSPACE}/utilities/utils/rebuild/
# cat ${WORKSPACE}/utilities/jenkins/built-test/full-build.extra_packages.txt >> packages.txt
./build.pl --stage 1 --to_stage=2 --source=${WORKSPACE} --workdir=${WORKSPACE}/build;

cd ${WORKSPACE}
ln -sbfv build/new/install.1 ./install
ls -lhcv

echo "-----------------------------------"
echo " Clang Tidy Check "
echo "-----------------------------------"

export OFFLINE_MAIN=$WORKSPACE/install
echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n new;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh -n new;


which clang-tidy; 
env;

cd ${WORKSPACE}
pwd
ls -lhcv

if test -f clang-tidy-result.txt; then
  mv -fv clang-tidy-result.txt clang-tidy-result.txt.backup
fi



# Concurrency: set NPROC=90 by default; override by exporting NPROC in Jenkins
NPROC="${NPROC:-90}"

# Directories to scan for source files. Add/remove as needed.
TARGET_DIRS=(
  "$WORKSPACE/coresoftware"
)

# Build a null-delimited file list to be safe with spaces and avoid ARG_MAX.
FILELIST="$(mktemp -p "${WORKSPACE}" ct_files.XXXXXX)"
> "$FILELIST"
for d in "${TARGET_DIRS[@]}"; do
  [[ -d "$d" ]] && find "$d" -type f \( -name '*.cc' -o -name '*.cpp' -o -name '*.C' \) -print0 >> "$FILELIST"
done

# Count files
TOTAL_FILES=$(tr -cd '\0' < "$FILELIST" | wc -c)
if [[ "$TOTAL_FILES" -eq 0 ]]; then
  echo "No source files found under: ${TARGET_DIRS[*]}"
  exit 0
fi

echo "Discovered $TOTAL_FILES files for clang-tidy"
OUTDIR="$WORKSPACE/clang-tidy-out"
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

# Compile flags for clang-tidy's underlying clang invocation
# (same flags you were passing after the --)
COMPILE_ARGS_STR="
  -Wall -Werror -Wshadow -std=c++20 -Wno-dangling
  -isystem$WORKSPACE/macros/common
  -isystem$OFFLINE_MAIN/include
  -isystem$ROOTSYS/include
  -isystem$G4_MAIN/include
  -isystem$G4_MAIN/include/Geant4
  -isystem$OPT_SPHENIX/include
  -isystem$OFFLINE_MAIN/rootmacros
  -DHomogeneousField -DEVTGEN_HEPMC3 -DRAVE -DRaveDllExport=
"

# Function that runs clang-tidy on a single file and writes per-file log
run_ct() {
  local file="$1"
  local rel="${file#${WORKSPACE}/}"
  local out="$OUTDIR/${rel}.txt"
  mkdir -p "$(dirname "$out")"

  # Progress note (may interleave in parallel; logs per file are clean)
  echo "[CT] $(date +'%H:%M:%S') $rel"

  # Run clang-tidy; write all output to the file's log
  # shellcheck disable=SC2086 # intentional word-splitting for compile args
  clang-tidy "$file" -- $COMPILE_ARGS_STR > "$out" 2>&1
  local rc=$?

  # Record failures for summary and proper exit code
  if [[ $rc -ne 0 ]]; then
    echo "$rel" >> "$OUTDIR/.failed"
  fi
  return $rc
}

export -f run_ct
export OUTDIR WORKSPACE COMPILE_ARGS_STR

# Run up to NPROC files at a time using xargs (widely available on Jenkins agents)
# -0: null-delimited input; -n1: one file per invocation; -P: parallel jobs
# We invoke a login shell to get the exported function and env.
xargs -0 -n 1 -P "$NPROC" bash -lc 'run_ct "$@"' _ < "$FILELIST"
XARGS_RC=$?

# Concatenate per-file logs into the legacy single result file in a stable order
: > "$WORKSPACE/clang-tidy-result.txt"
while IFS= read -r -d '' f; do
  rel="${f#${WORKSPACE}/}"
  [[ -f "$OUTDIR/${rel}.txt" ]] && cat "$OUTDIR/${rel}.txt" >> "$WORKSPACE/clang-tidy-result.txt"
done < "$FILELIST"

# Basic summary
ls -hvl "$WORKSPACE/clang-tidy-result.txt" || true
wc -l "$WORKSPACE/clang-tidy-result.txt"   || true
head -n 10 "$WORKSPACE/clang-tidy-result.txt" || true

# Exit with failure if any file failed
if [[ -s "$OUTDIR/.failed" || "$XARGS_RC" -ne 0 ]]; then
  echo "clang-tidy reported failures for the following files:"
  sort -u "$OUTDIR/.failed" || true
  exit 1
fi

# Clean up the temporary list
rm -f "$FILELIST"
