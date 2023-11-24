#!/bin/bash

FTS_DIR=/autofz_bench/fuzzer-test-suite

targets=(
    libxml2-v2.9.2
    openthread-2018-02-27
    proj4-2017-08-14 
    libjpeg-turbo-07-2017 
    freetype2-2017
    harfbuzz-1.3.2
    lcms-2017-03-21
    libpng-1.2.56
    openssl-1.0.1f
    re2-2014-12-09
    sqlite-2016-11-14
    vorbis-2017-12-11
    woff2-2016-05-06
)
rm -rf /d/p/justafl /d/p/aflasan /d/p/normal /d/p/cov
mkdir -p /d/p/justafl /d/p/aflasan /d/p/normal /d/p/cov
BUILD_DIR=/autofz_bench/fuzzer-test-suite-build
rm -rf $BUILD_DIR /seeds/fuzzer-test-suite
mkdir -p $BUILD_DIR /seeds/fuzzer-test-suite
cd $BUILD_DIR

FTS_DIR=/autofz_bench/fuzzer-test-suite

JOBS="-l$(nproc)" # make -j
export JOBS

for target in ${targets[@]};
do
    {

        # build with asan off
        CC=clang
        CXX=clang++
        CFLAGS='-O3 -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard,trace-cmp,trace-gep,trace-div'
        CXXFLAGS="$CFLAGS -stdlib=libc++"
        FUZZING_ENGINE=afl
        AFL_SRC=/fuzzer/afl
        LIBFUZZER_SRC=/llvm/compiler-rt-12.0.0.src/lib/fuzzer/
        export CC CXX CFLAGS CXXFLAGS FUZZING_ENGINE AFL_SRC LIBFUZZER_SRC
        BUILD_SCRIPT=$FTS_DIR/$target/build.sh
        RUNDIR="$target"
        rm -rf $RUNDIR
        mkdir -p $RUNDIR
        pushd .
        cd $RUNDIR
        $BUILD_SCRIPT > /dev/null
        for EXECUTABLE in $target*-out*;
        do
            NEW_NAME=${EXECUTABLE%-out*}
            NEW_DIR=/d/p/justafl/fuzzer-test-suite/$NEW_NAME
            NEW_PATH=$NEW_DIR/$NEW_NAME
            rm -rf $NEW_DIR
            mkdir -p $NEW_DIR
            mv $EXECUTABLE $NEW_PATH
        done
        popd

        # build with asan on
        CC=clang
        CXX=clang++
        CFLAGS='-O3 -fno-omit-frame-pointer -fsanitize=address -fsanitize-address-use-after-scope -fsanitize-coverage=trace-pc-guard,trace-cmp,trace-gep,trace-div'
        CXXFLAGS="$CFLAGS -stdlib=libc++"
        FUZZING_ENGINE=afl
        AFL_SRC=/fuzzer/afl
        LIBFUZZER_SRC=/llvm/compiler-rt-12.0.0.src/lib/fuzzer/
        export CC CXX CFLAGS CXXFLAGS FUZZING_ENGINE AFL_SRC LIBFUZZER_SRC
        BUILD_SCRIPT=$FTS_DIR/$target/build.sh
        RUNDIR="$target"
        rm -rf $RUNDIR
        mkdir -p $RUNDIR
        pushd .
        cd $RUNDIR
        $BUILD_SCRIPT > /dev/null

        for EXECUTABLE in $target*-out*;
        do
            NEW_NAME=${EXECUTABLE%-out*}
            NEW_DIR=/d/p/aflasan/fuzzer-test-suite/$NEW_NAME
            NEW_PATH=$NEW_DIR/$NEW_NAME
            rm -rf $NEW_DIR
            mkdir -p $NEW_DIR
            mv $EXECUTABLE $NEW_PATH
        done
        popd
        # build normal binary
        CC=clang
        CXX=clang++
        CFLAGS='-O3 -fno-omit-frame-pointer'
        CXXFLAGS="$CFLAGS -stdlib=libc++"
        FUZZING_ENGINE=coverage
        AFL_SRC=/fuzzer/afl
        LIBFUZZER_SRC=/llvm/compiler-rt-12.0.0.src/lib/fuzzer/
        export CC CXX CFLAGS CXXFLAGS FUZZING_ENGINE AFL_SRC LIBFUZZER_SRC
        BUILD_SCRIPT=$FTS_DIR/$target/build.sh
        RUNDIR="$target"
        rm -rf $RUNDIR
        mkdir -p $RUNDIR
        pushd .
        cd $RUNDIR
        $BUILD_SCRIPT > /dev/null
        for EXECUTABLE in $target*-out*;
        do
            NEW_NAME=${EXECUTABLE%-out*}
            NEW_DIR=/d/p/normal/fuzzer-test-suite/$NEW_NAME
            NEW_PATH=$NEW_DIR/$NEW_NAME
            rm -rf $NEW_DIR
            mkdir -p $NEW_DIR
            mv $EXECUTABLE $NEW_PATH
        done
        popd
    } #&
done
#wait

for target in ${targets[@]};
do
    {
        echo "build $target"
        RUNDIR="$target"
        rm -rf $RUNDIR
        mkdir -p $RUNDIR
        # build normal binary
        CC=clang
        CXX=clang++
        CFLAGS='-fprofile-arcs -ftest-coverage'
        CXXFLAGS="$CFLAGS -stdlib=libc++"
        FUZZING_ENGINE=coverage
        AFL_SRC=/fuzzer/afl
        LIBFUZZER_SRC=/llvm/compiler-rt-12.0.0.src/lib/fuzzer/
        export CC CXX CFLAGS CXXFLAGS FUZZING_ENGINE AFL_SRC LIBFUZZER_SRC
        BUILD_SCRIPT=$FTS_DIR/$target/build.sh
        RUNDIR="$target"
        rm -rf $RUNDIR
        mkdir -p $RUNDIR
        pushd .
        cd $RUNDIR
        $BUILD_SCRIPT > /dev/null
        for EXECUTABLE in $target*-out*;
        do
            NEW_NAME=${EXECUTABLE%-out*}
            NEW_DIR=/d/p/cov/fuzzer-test-suite/$NEW_NAME
            NEW_PATH=$NEW_DIR/$NEW_NAME
            rm -rf $NEW_DIR
            mkdir -p $NEW_DIR
            mv $EXECUTABLE $NEW_PATH
        done
        popd
    } #&
done
#wait



ls -alh /d/p/*
