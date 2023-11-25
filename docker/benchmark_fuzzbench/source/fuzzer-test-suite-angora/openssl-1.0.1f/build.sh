#!/bin/bash
# Copyright 2016 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh
export SRC="$PWD"
rm -rf /out
rm -rf /work
mkdir /out
mkdir /work
export WORK=/work
export OUT=/out
rm -rf openssl
git clone \
        --depth 1 \
        --branch openssl-3.0.7 \
        https://github.com/openssl/openssl.git


build_fuzzer

cp $LIB_FUZZING_ENGINE /usr/lib/libFuzzingEngine.a

pushd openssl
CONFIGURE_FLAGS=""
if [[ $CFLAGS = *sanitize=memory* ]]
then
  CONFIGURE_FLAGS="no-asm"
fi

WITH_FUZZER_LIB='/usr/lib/libFuzzingEngine'

set -x
./config --debug enable-fuzz-libfuzzer -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION no-shared enable-tls1_3 enable-rc5 enable-md2 enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method enable-nextprotoneg enable-weak-ssl-ciphers --with-fuzzer-lib=$WITH_FUZZER_LIB $CFLAGS -fno-sanitize=alignment $CONFIGURE_FLAGS

make -j$(nproc) LDCMD="$CXX $CXXFLAGS"

fuzzers=$(find fuzz -executable -type f '!' -name \*.py '!' -name \*-test '!' -name \*.pl)
for f in $fuzzers; do
	fuzzer=$(basename $f)
	cp $f $OUT/
	zip -j $OUT/${fuzzer}_seed_corpus.zip fuzz/corpora/${fuzzer}/*
done
set +x
cp fuzz/oids.txt $OUT/x509.dict
popd 


if [[ ! -d /seeds/fuzzer-test-suite/openssl-1.0.1f ]]; then
  mkdir -p /seeds/fuzzer-test-suite/openssl-1.0.1f
  python3 /autofz_bench/fuzzer-test-suite/openssl-1.0.1f/extract_seed.py
fi
if [[ ! -d /dicts/fuzzer-test-suite/openssl-1.0.1f  ]]; then
  mkdir -p /dicts/fuzzer-test-suite/openssl-1.0.1f
  cp  $OUT/x509.dict /dicts/fuzzer-test-suite/openssl-1.0.1f/
fi
cp /out/x509 openssl-1.0.1f-out