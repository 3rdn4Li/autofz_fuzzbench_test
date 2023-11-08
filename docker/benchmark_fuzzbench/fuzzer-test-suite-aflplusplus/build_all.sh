#!/bin/bash -e

FTS_DIR=/autofz_bench/fuzzer-test-suite-aflplusplus

targets=(
    freetype2
    harfbuzz
    #lcms
    #libjpeg
    #libpng
    #libxml
    #openssl
    #openthread
    #proj4
    #re2
    #sqlite
    #vorbis
    #woff2
)
mkdir -p /d/p/aflclangfast
mkdir -p /d/p/aflclangfastcmplog
BUILD_DIR=/autofz_bench/fuzzer-test-suite-build
mkdir -p $BUILD_DIR /autofz_bench/fuzzer-test-suite-seeds

cd $BUILD_DIR

JOBS=" " # make -j
export JOBS

export AFL_LLVM_USE_TRACE_PC=1
for target in ${targets[@]};
do
    {
        CC=afl-clang-fast
        CXX=afl-clang-fast++
        CFLAGS='-O2 -fno-omit-frame-pointer'
        CXXFLAGS="$CFLAGS -stdlib=libc++"
        FUZZING_ENGINE=aflpp
        AFLPP_SRC=/fuzzer/afl++
        LIBFUZZER_SRC=/llvm/compiler-rt-12.0.0.src/lib/fuzzer/
        export CC CXX CFLAGS CXXFLAGS FUZZING_ENGINE AFLPP_SRC LIBFUZZER_SRC
        BUILD_SCRIPT=$FTS_DIR/$target/build.sh
        RUNDIR="$target"
        mkdir -p $RUNDIR
        pushd .
        cd $RUNDIR
        $BUILD_SCRIPT > /dev/null
        for EXECUTABLE in $target*-out*;
        do
            NEW_NAME=${EXECUTABLE%-out*}
            NEW_DIR=/d/p/aflclangfast/fuzzer-test-suite/$NEW_NAME
            NEW_PATH=$NEW_DIR/$NEW_NAME
            mkdir -p $NEW_DIR
            mv $EXECUTABLE $NEW_PATH
        done
        popd

        CC=afl-clang-fast
        CXX=afl-clang-fast++
        CFLAGS='-O2 -fno-omit-frame-pointer'
        CXXFLAGS="$CFLAGS -stdlib=libc++"
        FUZZING_ENGINE=aflpp
        AFLPP_SRC=/fuzzer/afl++
        LIBFUZZER_SRC=/llvm/compiler-rt-12.0.0.src/lib/fuzzer/
        export CC CXX CFLAGS CXXFLAGS FUZZING_ENGINE AFPPL_SRC LIBFUZZER_SRC
        BUILD_SCRIPT=$FTS_DIR/$target/build.sh
        RUNDIR="$target"
        mkdir -p $RUNDIR
        pushd .
        cd $RUNDIR
        AFL_LLVM_CMPLOG=1 $BUILD_SCRIPT > /dev/null
        for EXECUTABLE in $target*-out*;
        do
            NEW_NAME=${EXECUTABLE%-out*}
            NEW_DIR=/d/p/aflclangfastcmplog/fuzzer-test-suite/$NEW_NAME
            NEW_PATH=$NEW_DIR/$NEW_NAME
            mkdir -p $NEW_DIR
            mv $EXECUTABLE $NEW_PATH
        done
        popd
    } &
done
wait

cp -r $BUILD_DIR/openssl-1.0.1f/runtime /d/p/aflclangfast/fuzzer-test-suite/openssl-1.0.1f/
cp -r $BUILD_DIR/openssl-1.0.1f/runtime /d/p/aflclangfastcmplog/fuzzer-test-suite/openssl-1.0.1f/

ls -alh /d/p/*
