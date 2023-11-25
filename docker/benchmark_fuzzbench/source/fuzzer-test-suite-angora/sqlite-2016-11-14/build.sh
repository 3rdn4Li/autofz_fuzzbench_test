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

if [[ ! -d $SRC/sqlite3  ]]; then
mkdir $SRC/sqlite3 && \
    cd $SRC/sqlite3 && \
    curl 'https://sqlite.org/src/tarball/sqlite.tar.gz?r=c78cbf2e86850cc6' -o sqlite3.tar.gz && \
        tar xzf sqlite3.tar.gz --strip-components 1
cd ..
fi
find $SRC/sqlite3 -name "*.test" | xargs zip $OUT/ossfuzz_seed_corpus.zip
build_fuzzer
cp $LIB_FUZZING_ENGINE /lib/x86_64-linux-gnu/
if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi

pushd sqlite3
set -x
echo $PWD
set +x
mkdir build
cp ../$LIB_FUZZING_ENGINE build/
cd build

export ASAN_OPTIONS=detect_leaks=0

# Limit max length of data blobs and sql queries to prevent irrelevant OOMs.
# Also limit max memory page count to avoid creating large databases.
export CFLAGS="$CFLAGS -DSQLITE_MAX_LENGTH=128000000 \
               -DSQLITE_MAX_SQL_LENGTH=128000000 \
               -DSQLITE_MAX_MEMORY=25000000 \
               -DSQLITE_PRINTF_PRECISION_LIMIT=1048576 \
               -DSQLITE_DEBUG=1 \
               -DSQLITE_MAX_PAGE_COUNT=16384"             
../configure
make clean
make -j$(nproc) 
make sqlite3.c

$CC $CFLAGS -I. -c \
    $SRC/sqlite3/test/ossfuzz.c -o $SRC/sqlite3/test/ossfuzz.o

$CXX $CXXFLAGS \
    $SRC/sqlite3/test/ossfuzz.o -o $OUT/ossfuzz \
    $LIB_FUZZING_ENGINE ./sqlite3.o -pthread -ldl -lz
popd

if [[ ! -d /dicts/fuzzer-test-suite/sqlite-2016-11-14  ]]; then
  mkdir -p /dicts/fuzzer-test-suite/sqlite-2016-11-14
  cp /autofz_bench/fuzzer-test-suite/sqlite-2016-11-14/ossfuzz.dict /dicts/fuzzer-test-suite/sqlite-2016-11-14
fi
if [[ ! -d /seeds/fuzzer-test-suite/sqlite-2016-11-14 ]]; then
  mkdir -p /seeds/fuzzer-test-suite/sqlite-2016-11-14
  python3 /autofz_bench/fuzzer-test-suite/sqlite-2016-11-14/extract_seed.py
fi
cp /out/ossfuzz sqlite-2016-11-14-out