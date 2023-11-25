#!/bin/bash
# Copyright 2016 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh

apt-get update && \
    apt-get install -y --no-install-recommends \
        make autoconf libtool pkg-config \
        zlib1g-dev  liblzma-dev 
curl -LO http://mirrors.kernel.org/ubuntu/pool/main/a/automake-1.16/automake_1.16.5-1.3_all.deb && \
    apt install ./automake_1.16.5-1.3_all.deb
rm -rf libxml2
get_git_revision https://gitlab.gnome.org/GNOME/libxml2.git c7260a47f19e01f4f663b6a56fbdc2dafd8a6e7e libxml2
export SRC="$PWD"
rm -rf /out
rm -rf /work
mkdir /out
mkdir /work
export WORK=/work
export OUT=/out
build_fuzzer

if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi
cp $LIB_FUZZING_ENGINE /lib/x86_64-linux-gnu/
cp $LIB_FUZZING_ENGINE libxml2/fuzz

pushd libxml2
export CFLAGS="$CFLAGS -fno-omit-frame-pointer -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
export CXXFLAGS="$CXXFLAGS -fno-omit-frame-pointer -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"


export V=1
set -x
./autogen.sh \
    --disable-shared \
    --without-debug \
    --without-ftp \
    --without-http \
    --without-legacy \
    --without-python
make -j$(nproc)

cd fuzz
make clean-corpus
make fuzz.o
make xml.o
# Link with $CXX
$CXX $CXXFLAGS \
    xml.o fuzz.o \
    -o $OUT/xml \
    $LIB_FUZZING_ENGINE \
    ../.libs/libxml2.a -Wl,-Bstatic -lz -llzma -Wl,-Bdynamic
[ -e seed/xml ] || make seed/xml.stamp 

set +x
if [[ ! -d /seeds/fuzzer-test-suite/libxml2-v2.9.2 ]]; then
  zip -j $OUT/xml_seed_corpus.zip seed/xml/*
  mkdir -p /seeds/fuzzer-test-suite/libxml2-v2.9.2
  python3 /autofz_bench/fuzzer-test-suite/libxml2-v2.9.2/extract_seed.py
fi

if [[ ! -d /dicts/fuzzer-test-suite/libxml2-v2.9.2 ]]; then
  mkdir -p /dicts/fuzzer-test-suite/libxml2-v2.9.2
  cp cp *.dict /dicts/fuzzer-test-suite/libxml2-v2.9.2/
fi
popd

cp /out/xml libxml2-v2.9.2-out