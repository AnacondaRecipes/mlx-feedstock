#!/bin/bash

set -exuo pipefail

export PYPI_RELEASE=1
export CMAKE_GENERATOR=Ninja
export CMAKE_BUILD_PARALLEL_LEVEL=""

# Build CPU-only. The PBP macOS workers' Metal shader compiler predates Metal 3.1
# (no `bfloat` support), so mlx's GPU kernels cannot be compiled here.
export CMAKE_ARGS="${CMAKE_ARGS} -DMLX_BUILD_METAL=OFF"

# CANARY: no sysroot repointing here. Assert what the stdlib('c') activation left us with.
ls /Library/Developer/CommandLineTools/SDKs/
echo "CANARY MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-unset} OSX_SDK_VER=${OSX_SDK_VER:-unset}"
echo "CANARY CONDA_BUILD_SYSROOT=${CONDA_BUILD_SYSROOT:-unset} SDKROOT=${SDKROOT:-unset}"
echo "CANARY CMAKE_ARGS=${CMAKE_ARGS:-unset}"
echo "CANARY CPPFLAGS=${CPPFLAGS:-unset}"
[[ "${MACOSX_DEPLOYMENT_TARGET}" == "13.3" ]]
[[ "${CONDA_BUILD_SYSROOT}" == */MacOSX14.5.sdk ]]
[[ "${SDKROOT}" == */MacOSX14.5.sdk ]]
test -d "${CONDA_BUILD_SYSROOT}"

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_OSX_ARCHITECTURES=arm64"
fi

export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PREFIX_PATH=${PREFIX};${SP_DIR} -DPython_EXECUTABLE=$PYTHON -DPython_INCLUDE_DIR=${PREFIX}/include/python${PY_VER}"

$PYTHON -m pip install . -vv --no-deps --no-build-isolation
