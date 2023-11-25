ARG PREFIX
FROM $PREFIX/base

WORKDIR /fuzzer


RUN git clone https://github.com/AngoraFuzzer/Angora /fuzzer/angora \
    && cd /fuzzer/angora \
    && git checkout 6b46c8553970a71de42c0d274d166876ef478b51



ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PIN_ROOT=/pin-3.7-97619-g0d0c92f4f-gcc-linux \
    GOPATH=/go \
    PATH=/fuzzer/angora/clang+llvm/bin:/usr/local/cargo/bin:/fuzzer/angora/bin/:/go/bin:$PATH \
    LD_LIBRARY_PATH=/fuzzer/angora/clang+llvm/lib:$LD_LIBRARY_PATH

WORKDIR /fuzzer/angora

RUN ./build/install_rust.sh
RUN wget -q https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz \
    && tar -C /fuzzer/angora -xf clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz \
    && rm clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz \
    && mv /fuzzer/angora/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu- /fuzzer/angora/clang+llvm

# RUN sed -e '1146 s|^|//|' \
#      -i /fuzzer/angora/llvm_mode/dfsan_rt/sanitizer_common/sanitizer_platform_limits_posix.cc
# # fix a problem introduced by Glibc-2.31, commented CHECK_SIZE_AND_OFFSET(ipc_perm, mode); 

RUN ln -s /usr/bin/python3 /usr/bin/python
# FIXME: go get cannot specify version in ubuntu 16.04 ...
#RUN sed -i 's/go get/#go get/g' /fuzzer/angora/build/install_tools.sh
#RUN ./build/install_tools.sh

# no15k
# https://github.com/unifuzz/dockerized_fuzzing/blob/master/angora/Dockerfile.no15k
RUN sed -i 's/15000/1048576/g' /fuzzer/angora/common/src/config.rs
RUN ./build/build.sh
#RUN ./build/install_pin_mode.sh

ENV CC=/fuzzer/angora/bin/angora-clang CXX=/fuzzer/angora/bin/angora-clang++ LD=/fuzzer/angora/bin/angora-clang
