#!/bin/bash
# Copyright 2017 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh

get_git_revision https://github.com/google/re2.git b025c6a3ae05995660e3b882eb3277f4399ced1a re2
export SRC="$PWD"
rm -rf /out
rm -rf /work
mkdir /out
mkdir /work
export WORK=/work
export OUT=/out

export CXXFLAGS="$CXXFLAGS -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument -stdlib=libc++ -O3"
export CFLAGS="$CFLAGS -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument "

build_fuzzer
cp $LIB_FUZZING_ENGINE /lib/x86_64-linux-gnu/
cp $LIB_FUZZING_ENGINE re2
if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi
set -x
pushd re2
make clean
make -j $(nproc)


$CXX $CXXFLAGS /autofz_bench/fuzzer-test-suite/re2-2014-12-09/target.cc -I . obj/libre2.a -lpthread $LIB_FUZZING_ENGINE \
    -o $OUT/fuzzer
set +x
popd
if [[ ! -d /seeds/fuzzer-test-suite/re2-2014-12-09 ]]; then
  mkdir -p /seeds/fuzzer-test-suite/re2-2014-12-09
  echo "hi" > /seeds/fuzzer-test-suite/re2-2014-12-09/default_seed
fi
wget -qO fuzzer.dict \
    https://raw.githubusercontent.com/google/fuzzing/master/dictionaries/regexp.dict
if [[ ! -d /dicts/fuzzer-test-suite/re2-2014-12-09  ]]; then
  mkdir -p /dicts/fuzzer-test-suite/re2-2014-12-09
  cp fuzzer.dict /dicts/fuzzer-test-suite/re2-2014-12-09/
fi

cp /out/fuzzer re2-2014-12-09-out