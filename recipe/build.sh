#!/bin/bash

set -exuo pipefail

export PYPI_RELEASE=1
export CMAKE_GENERATOR=Ninja
export CMAKE_BUILD_PARALLEL_LEVEL=""

# Build CPU-only. The PBP macOS workers' Metal shader compiler predates Metal 3.1
# (no `bfloat` support), so mlx's GPU kernels cannot be compiled here. The CPU
# backend uses Apple's Accelerate framework, which needs no external BLAS.
export CMAKE_ARGS="${CMAKE_ARGS} -DMLX_BUILD_METAL=OFF"

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_OSX_ARCHITECTURES=arm64"
fi

export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PREFIX_PATH=${PREFIX};${SP_DIR} -DPython_EXECUTABLE=$PYTHON -DPython_INCLUDE_DIR=${PREFIX}/include/python${PY_VER}"

$PYTHON -m pip install . -vv --no-deps --no-build-isolation
