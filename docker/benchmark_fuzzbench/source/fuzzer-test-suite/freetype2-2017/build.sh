#!/bin/bash
# Copyright 2017 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh

build_lib() {
  rm -rf BUILD
  cp -rf SRC BUILD
  (cd BUILD && ./autogen.sh && ./configure --disable-shared --with-harfbuzz=no --with-bzip2=no --with-png=no && make clean && make all -j $JOBS)
}

get_git_revision git://git.sv.nongnu.org/freetype/freetype2.git cd02d359a6d0455e9d16b87bf9665961c4699538 SRC
build_lib
build_fuzzer

if [[ ! -d /seeds/fuzzer-test-suite/freetype2-2017 ]]; then
  mkdir -p /seeds/fuzzer-test-suite/freetype2-2017
  git clone https://github.com/unicode-org/text-rendering-tests.git TRT
  # TRT/fonts is the full seed folder, but they're too big
  cp TRT/fonts/TestKERNOne.otf /seeds/fuzzer-test-suite/freetype2-2017
  cp TRT/fonts/TestGLYFOne.ttf /seeds/fuzzer-test-suite/freetype2-2017
fi

if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi
set -x
$CXX $CXXFLAGS -std=c++11 -I BUILD/include -I BUILD/ BUILD/src/tools/ftfuzzer/ftfuzzer.cc BUILD/objs/.libs/libfreetype.a  $LIB_FUZZING_ENGINE -larchive -lz -o $EXECUTABLE_NAME_BASE-$EXECUTABLE_NAME_EXT

