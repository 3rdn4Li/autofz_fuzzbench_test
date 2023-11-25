#!/bin/bash
# Copyright 2017 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh
apt-get update && \
    apt-get install -y \
        make autoconf automake libtool g++ pkg-config wget liblzma-dev zlib1g-dev libssl-dev libsqlite3-dev sqlite3


echo "/usr/lib/x86_64-linux-gnu/libsqlite3.so.0"|grep .so|sort|uniq|sed 's#^/lib#/usr/lib#g'|sed 's#\.so.*$#.so#g'|grep -v libgcc_s.so|grep -v libstdc++.so|grep -v libc.so|grep -v libm.so|grep -v libpthread.so|xargs -i /fuzzer/angora/tools/gen_library_abilist.sh '{}' discard >> /tmp/abilist.txt

export CXXFLAGS="$CXXFLAGS -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument -stdlib=libc++ -O3"
export CFLAGS="$CFLAGS -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument "

rm -rf PROJ

git clone https://github.com/OSGeo/PROJ PROJ && \
git -C PROJ checkout a7482d3775f2e346f3680363dd2d641add3e68b2

git clone https://github.com/curl/curl.git PROJ/curl && \
git -C PROJ/curl checkout c12fb3ddaf48e709a7a4deaa55ec485e4df163ee

git clone https://gitlab.com/libtiff/libtiff.git PROJ/libtiff && \
git -C PROJ/libtiff checkout c8e1289deff3fa60ba833ccec6c030934b02c281

export SRC="$PWD"
rm -rf /out
rm -rf /work
mkdir /out
mkdir /work
export WORK=/work
export OUT=/out

build_fuzzer
cp $LIB_FUZZING_ENGINE /lib/x86_64-linux-gnu/

pushd  PROJ
set -x
# build libcurl.a (builing against Ubuntu libcurl.a doesn't work easily)
cd curl
autoreconf -i
#with-openssl can't be built with taint
./configure --disable-shared --without-libidn2 --without-ssl --prefix=$SRC/install
make clean -s
set -x
make -j$(nproc) 
make install
set +x
cd ..

# build libtiff.a
cd libtiff
./autogen.sh
./configure --disable-shared --disable-jbig --disable-jpeg --prefix=$SRC/install
make -j$(nproc)
make install
cd ..

mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS:BOOL=OFF \
        -DCURL_INCLUDE_DIR:PATH="$SRC/install/include" \
        -DCURL_LIBRARY_RELEASE:FILEPATH="$SRC/install/lib/libcurl.a" \
        -DTIFF_INCLUDE_DIR:PATH="$SRC/install/include" \
        -DTIFF_LIBRARY_RELEASE:FILEPATH="$SRC/install/lib/libtiff.a" \
        -DCMAKE_INSTALL_PREFIX=$SRC/install \
        -DBUILD_APPS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF
make -j$(nproc)  
make install
cd ..

EXTRA_LIBS="-lpthread -Wl,-Bstatic -lsqlite3 -L$SRC/install/lib -ltiff -lcurl -lcrypto -lz -Wl,-Bdynamic" #removed -lssl 

build_fuzzer()
{
    fuzzerName=$1
    sourceFilename=$2
    shift
    shift
    echo "Building fuzzer $fuzzerName"
    $CXX $CXXFLAGS -std=c++11 -fvisibility=hidden -llzma -Isrc -Iinclude \
        $sourceFilename $* -o $OUT/$fuzzerName \
        $LIB_FUZZING_ENGINE "$SRC/install/lib/libproj.a" $EXTRA_LIBS
}
cp $SRC/$LIB_FUZZING_ENGINE .
build_fuzzer proj_crs_to_crs_fuzzer test/fuzzers/proj_crs_to_crs_fuzzer.cpp




set +x
cp -r data/* $OUT

popd
cp /out/proj_crs_to_crs_fuzzer proj4-2017-08-14-out
if [[ ! -d /seeds/fuzzer-test-suite/proj4-2017-08-14 ]]; then
  mkdir -p /seeds/fuzzer-test-suite/proj4-2017-08-14
  echo "hi" > /seeds/fuzzer-test-suite/proj4-2017-08-14/default_seed
fi