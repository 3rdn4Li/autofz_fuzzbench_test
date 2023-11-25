#!/bin/bash
set -x
targets=(
    # freetype2-2017
    # harfbuzz-1.3.2
    # lcms-2017-03-21
    # libjpeg-turbo-07-2017
    # libpng-1.2.56
    # libxml2-v2.9.2
    openssl-1.0.1f #undefined reference to `dfs$OPENSSL_cleanse'..
    # openthread-2018-02-27
    #proj4-2017-08-14 #
    # re2-2014-12-09
    #sqlite-2016-11-14
    # vorbis-2017-12-11
    # woff2-2016-05-06
)

export RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \/go/bin:$PATH \
    LD_LIBRARY_PATH=/clang+llvm/lib:$LD_LIBRARY_PATH

BUILD_DIR=/autofz_bench/fuzzer-test-suite-build
mkdir -p $BUILD_DIR /autofz_bench/fuzzer-test-suite-seeds

cd $BUILD_DIR

FTS_DIR=/autofz_bench/fuzzer-test-suite-angora

JOBS=" " # make -j
export JOBS

ldd /d/p/normal/*/*/*|grep .so|awk '{print $3}'|grep .so|sort|uniq|sed 's#^/lib#/usr/lib#g'|sed 's#\.so.*$#.so#g'|grep -v libgcc_s.so|grep -v libstdc++.so|grep -v libc.so|grep -v libm.so|grep -v libpthread.so|xargs -i /fuzzer/angora/tools/gen_library_abilist.sh '{}' discard > /tmp/abilist.txt

export ANGORA_TAINT_RULE_LIST=/tmp/abilist.txt

for target in ${targets[@]};
do
    {
        echo "Build $target"
        # # build with asan off
        # CC=/fuzzer/angora/bin/angora-clang
        # CXX=/fuzzer/angora/bin/angora-clang++
        # CFLAGS='-O3 -fno-omit-frame-pointer'
        # CXXFLAGS="$CFLAGS -stdlib=libc++"
        # FUZZING_ENGINE=coverage
        # AFL_SRC=/fuzzer/afl
        # LIBFUZZER_SRC=/llvm/compiler-rt-12.0.0.src/lib/fuzzer/
        # export CC CXX CFLAGS CXXFLAGS FUZZING_ENGINE AFL_SRC LIBFUZZER_SRC
        # BUILD_SCRIPT=$FTS_DIR/$target/build.sh
        # RUNDIR="$target"
        # mkdir -p $RUNDIR
        # pushd .
        # cd $RUNDIR
        # USE_FAST=1 $BUILD_SCRIPT > /dev/null
        # for EXECUTABLE in $target*-out*;
        # do
        #     NEW_NAME=${EXECUTABLE%-out*}
        #     NEW_DIR=/d/p/angora/fast/fuzzer-test-suite/$NEW_NAME
        #     NEW_PATH=$NEW_DIR/$NEW_NAME
        #     mkdir -p $NEW_DIR
        #     mv $EXECUTABLE $NEW_PATH
        # done
        # popd
        #build with asan off
        CC=/fuzzer/angora/bin/angora-clang
        CXX=/fuzzer/angora/bin/angora-clang++
        CFLAGS='-O3 -fno-omit-frame-pointer'
        CXXFLAGS="$CFLAGS  -stdlib=libc++"
        FUZZING_ENGINE=coverage
        AFL_SRC=/fuzzer/afl
        LIBFUZZER_SRC=/llvm/compiler-rt-12.0.0.src/lib/fuzzer/
        export CC CXX CFLAGS CXXFLAGS FUZZING_ENGINE AFL_SRC LIBFUZZER_SRC
        BUILD_SCRIPT=$FTS_DIR/$target/build.sh
        RUNDIR="$target"
        mkdir -p $RUNDIR
        pushd .
        cd $RUNDIR
        USE_TRACK=1 $BUILD_SCRIPT
        for EXECUTABLE in $target*-out*;
        do
            NEW_NAME=${EXECUTABLE%-out*}
            NEW_DIR=/d/p/angora/taint/fuzzer-test-suite/$NEW_NAME
            NEW_PATH=$NEW_DIR/$NEW_NAME
            mkdir -p $NEW_DIR
            mv $EXECUTABLE $NEW_PATH
        done
        popd
    } 
done
wait

set +x
# cp -r $BUILD_DIR/openssl-1.0.1f/runtime /d/p/angora/fast/fuzzer-test-suite/openssl-1.0.1f/
# cp -r $BUILD_DIR/openssl-1.0.1f/runtime /d/p/angora/taint/fuzzer-test-suite/openssl-1.0.1f/

ls -alh /d/p/*
