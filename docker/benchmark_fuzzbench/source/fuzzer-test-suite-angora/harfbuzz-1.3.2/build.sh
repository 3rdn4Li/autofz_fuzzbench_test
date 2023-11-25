#!/bin/bash
# Copyright 2016 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh

get_git_revision https://github.com/behdad/harfbuzz.git  cb47dca74cbf6d147aac9cf3067f249555aa68b1 SRC

build_fuzzer
#pip install --upgrade pip

python3.8 -m pip install ninja meson==0.56.0

# Disable:
# 1. UBSan vptr since target built with -fno-rtti.
export CFLAGS="$CFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"
export CXXFLAGS="$CXXFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY -std=c++11"


# setup
build=BUILD

# cleanup
rm -rf $build
mkdir -p $build
# Build the library.
# set -x
# "$(echo $LIB_FUZZING_ENGINE)"
# sleep 200
# set +x
# if [[ $FUZZING_ENGINE == "hooks" ]]; then
#   # Link ASan runtime so we can hook memcmp et al.
#   LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
# fi

cd SRC && meson --default-library=static --wrap-mode=nodownload \
      -Dexperimental_api=true \
      -Dfuzzer_ldflags="$(echo $LIB_FUZZING_ENGINE)" \
      ../$build \
  || (cat build/meson-logs/meson-log.txt && false)

cd .. && cp *.a BUILD

# Build the fuzzers.

ninja --verbose -j$(nproc) -C $build test/fuzzing/hb-shape-fuzzer 1>&2

# mv $build/test/fuzzing/hb-shape-fuzzer $OUT/

# Archive and copy to $OUT seed corpus if the build succeeded.

if [[ ! -d /seeds/fuzzer-test-suite/harfbuzz-1.3.2 ]]; then
    mkdir -p all-fonts
    mkdir -p /seeds/fuzzer-test-suite/harfbuzz-1.3.2
    for d in \
        SRC/test/shape/data/in-house/fonts \
        SRC/test/shape/data/aots/fonts \
        SRC/test/shape/data/text-rendering-tests/fonts \
        SRC/test/api/fonts \
        SRC/test/fuzzing/fonts \
        SRC/perf/fonts \
        ; do
        cp $d/* all-fonts/
    done
    cp all-fonts/* /seeds/fuzzer-test-suite/harfbuzz-1.3.2
fi

cp BUILD/test/fuzzing/hb-shape-fuzzer harfbuzz-1.3.2-out