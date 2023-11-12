#!/bin/bash -e
SCRIPT_DIR=$(dirname $(realpath $0))

$SCRIPT_DIR/fuzzer_fuzzbench/build.sh
$SCRIPT_DIR/benchmark_fuzzbench/build.sh

wait
