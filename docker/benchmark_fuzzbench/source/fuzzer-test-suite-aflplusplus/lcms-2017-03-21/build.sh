#!/bin/bash
# Copyright 2017 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh

build_lib() {
  rm -rf BUILD
  cp -rf SRC BUILD
  (cd BUILD && ./autogen.sh && ./configure --disable-shared && make -j $JOBS)
}

get_git_revision https://github.com/mm2/Little-CMS.git f0d963261b28253999e239a844ac74d5a8960f40 SRC
build_lib
build_fuzzer

if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi
set -x
$CXX $CXXFLAGS ${SCRIPT_DIR}/cms_transform_fuzzer.c -I BUILD/include/ BUILD/src/.libs/liblcms2.a $LIB_FUZZING_ENGINE -o $EXECUTABLE_NAME_BASE-$EXECUTABLE_NAME_EXT

if [[ ! -d /seeds/fuzzer-test-suite/lcms-2017-03-21 ]]; then
  mkdir -p /seeds/fuzzer-test-suite/lcms-2017-03-21
  cp /autofz_bench/fuzzer-test-suite/lcms-2017-03-21/seeds/* /seeds/fuzzer-test-suite/lcms-2017-03-21/
fi