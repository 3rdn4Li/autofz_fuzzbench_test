#!/bin/bash
# Copyright 2018 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh

get_git_revision https://github.com/openthread/openthread.git "25506997f286fdbfa72725f4cee78c922c896255" openthread
build_fuzzer 
cp $LIB_FUZZING_ENGINE /lib/x86_64-linux-gnu/
export SRC="$PWD"
rm -rf /out
rm -rf /work
mkdir /out
mkdir /work
export WORK=/work
export OUT=/out

pushd openthread
rm -rf build
bash tests/fuzz/oss-fuzz-build
popd

cp /out/ot-ip6-send-fuzzer openthread-2018-02-27-out
if [[ ! -d /seeds/fuzzer-test-suite/openthread-2018-02-27 ]]; then
  mkdir -p /seeds/fuzzer-test-suite/openthread-2018-02-27
  echo "hi" > /seeds/fuzzer-test-suite/openthread-2018-02-27/default_seed
fi