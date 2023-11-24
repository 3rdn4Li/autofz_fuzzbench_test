#!/bin/bash
# Copyright 2017 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh
apt-get update && \
    apt-get install -y make yasm cmake
get_git_revision https://github.com/libjpeg-turbo/libjpeg-turbo.git 3b19db4e6e7493a748369974819b4c5fa84c7614 SRC
get_git_revision https://github.com/libjpeg-turbo/seed-corpora 7c9ea5ffaac76ef618657978c9fdfa845d310b93 seed-corpora
#FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION, what a hidden env
export CXXFLAGS="$CXXFLAGS -O1 -fno-omit-frame-pointer -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION  -std=c++11"
export CFLAGS="$CFLAGS -O1 -fno-omit-frame-pointer -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
#what a hidden env!
export SRC="$PWD"

#seeds
set -x
pushd seed-corpora && \
zip -r ../decompress_fuzzer_seed_corpus.zip \
        afl-testcases/jpeg* \
        bugs/decompress*        
zip -r ../compress_fuzzer_seed_corpus.zip \
        afl-testcases/bmp \
        afl-testcases/gif* \
        bugs/compress* 
popd
set +x
rm -rf seed-corpora
rm -rf /out
rm -rf /work
mkdir /out
mkdir /work
export WORK=/work
export OUT=/out
build_fuzzer

# if [[ $FUZZING_ENGINE == "hooks" ]]; then
#   # Link ASan runtime so we can hook memcmp et al.
#   LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
# fi
# cp libFuzzingEngine-afl.a SRC
# cp libFuzzingEngine-coverage.a SRC
set -e
set -u
#export  LIB_FUZZING_ENGINE=libFuzzingEngine-afl.a

cp $LIB_FUZZING_ENGINE /lib/x86_64-linux-gnu

pushd SRC
        chmod +x fuzz/build.sh
        fuzz/build.sh
popd

echo $PWD

cp /out/libjpeg_turbo_fuzzer libjpeg-turbo-07-2017-out
if [[ ! -d /seeds/fuzzer-test-suite/libjpeg-turbo-07-2017 ]]; then
    mkdir /seeds/fuzzer-test-suite/libjpeg-turbo-07-2017
    python3 /autofz_bench/fuzzer-test-suite/libjpeg-turbo-07-2017/extract_seed.py
fi