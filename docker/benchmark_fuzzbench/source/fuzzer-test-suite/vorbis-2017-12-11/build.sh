#!/bin/bash
# Copyright 2017 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh

readonly INSTALL_DIR="$PWD/INSTALL"

build_ogg() {
  rm -rf BUILD/ogg
  mkdir -p BUILD/ogg $INSTALL_DIR
  cp -r SRC/ogg/* BUILD/ogg/
  (cd BUILD/ogg && ./autogen.sh && ./configure \
    --prefix="$INSTALL_DIR" \
    --enable-static \
    --disable-shared \
    --disable-crc \
    && make clean && make -j $JOBS && make install)
}

build_vorbis() {
  rm -rf BUILD/vorbis
  mkdir -p BUILD/vorbis $INSTALL_DIR
  cp -r SRC/vorbis/* BUILD/vorbis/
  (cd BUILD/vorbis && ./autogen.sh && ./configure \
    --prefix="$INSTALL_DIR" \
    --enable-static \
    --disable-shared \
    && make clean && make -j $JOBS && make install)
}

download_fuzz_target() {
  [[ ! -e SRC/oss-fuzz ]] && \
    git clone -n https://github.com/google/oss-fuzz.git SRC/oss-fuzz
  (cd SRC/oss-fuzz && git checkout 688aadaf44499ddada755562109e5ca5eb3c5662 \
    projects/vorbis/decode_fuzzer.cc)
}

get_git_revision https://github.com/xiph/ogg.git \
  c8391c2b267a7faf9a09df66b1f7d324e9eb7766 SRC/ogg
get_git_revision https://github.com/xiph/vorbis.git \
  84c023699cdf023a32fa4ded32019f194afcdad0 SRC/vorbis
download_fuzz_target

build_ogg
build_vorbis
build_fuzzer

if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi

$CXX $CXXFLAGS SRC/oss-fuzz/projects/vorbis/decode_fuzzer.cc \
  -o $EXECUTABLE_NAME_BASE-$EXECUTABLE_NAME_EXT -L"$INSTALL_DIR/lib" -I"$INSTALL_DIR/include" \
  $LIB_FUZZING_ENGINE -lvorbisfile  -lvorbis -logg

if [[ ! -d /seeds/fuzzer-test-suite/vorbis-2017-12-11 ]]; then
  mkdir -p /seeds/fuzzer-test-suite/vorbis-2017-12-11
  cp /autofz_bench/fuzzer-test-suite/vorbis-2017-12-11/seeds/* /seeds/fuzzer-test-suite/vorbis-2017-12-11/
fi