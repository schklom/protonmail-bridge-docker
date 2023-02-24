#!/bin/bash

set -ex

GOLANG_VERSION=1.18.7

ARCH=$(uname -m)
if [[ $ARCH == "riscv64" ]]; then
    # There is no official riscv64 release. Use carlosedp/riscv-bringup instead.
    wget

