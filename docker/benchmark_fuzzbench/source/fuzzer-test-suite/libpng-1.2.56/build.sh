#!/bin/bash
# Copyright 2016 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh


apt-get update && \
    apt-get install -y \
    make \
    autoconf \
    automake \
    libtool \
    zlib1g-dev

get_git_revision https://github.com/glennrp/libpng.git cd0ea2a7f53b603d3d9b5b891c779c430047b39a libpng
export SRC="$PWD"
rm -rf /out
rm -rf /work
mkdir /out
mkdir /work
export WORK=/work
export OUT=/out
cp libpng/contrib/oss-fuzz/build.sh $SRC/build2.sh
export CXXFLAGS="$CXXFLAGS -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument  -std=c++11"
export CFLAGS="$CFLAGS -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument "
build_fuzzer 
cp $LIB_FUZZING_ENGINE /lib/x86_64-linux-gnu/libFuzzingEngine.a

if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi

set -x
pushd libpng
$SRC/build2.sh
popd
set +x


wget --no-check-certificate -qO libpng_read_fuzzer.dict \
    https://raw.githubusercontent.com/google/fuzzing/master/dictionaries/png.dict
if [[ ! -d /dicts/fuzzer-test-suite/libpng-1.2.56 ]]; then
  mkdir -p /dicts/fuzzer-test-suite/libpng-1.2.56
  cp libpng_read_fuzzer.dict /dicts/fuzzer-test-suite/libpng-1.2.56/
  cp /out/png.dict /dicts/fuzzer-test-suite/libpng-1.2.56/
fi
cp /out/libpng_read_fuzzer libpng-1.2.56-out
if [[ ! -d /seeds/fuzzer-test-suite/libpng-1.2.56 ]]; then
  mkdir -p /seeds/fuzzer-test-suite/libpng-1.2.56
  #cp /autofz_bench/fuzzer-test-suite/libpng-1.2.56/seeds/* /seeds/fuzzer-test-suite/libpng-1.2.56/ in fuzzbench this seed is not copied to the right place
  python3 /autofz_bench/fuzzer-test-suite/libpng-1.2.56/extract_seed.py
fi
