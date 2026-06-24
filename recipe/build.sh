#!/bin/bash

set -exuo pipefail

export PYPI_RELEASE=1
export CMAKE_GENERATOR=Ninja
export CMAKE_BUILD_PARALLEL_LEVEL=""

# Build CPU-only. The PBP macOS workers' Metal shader compiler predates Metal 3.1
# (no `bfloat` support), so mlx's GPU kernels cannot be compiled here.
export CMAKE_ARGS="${CMAKE_ARGS} -DMLX_BUILD_METAL=OFF"

# mlx's CPU backend uses Apple Accelerate's "new LAPACK" (macOS 13.3+). We target
# macOS 13.3 (see conda_build_config.yaml) so the package installs on the Ventura
# (13.x) workers and macOS 13.3+ users. The matching 13.3 SDK is not on the
# workers, so build against the 14.5 SDK, which ships the same new-LAPACK headers.
# Repoint CONDA_BUILD_SYSROOT (and the -isysroot already baked into *FLAGS) from
# the absent 13.3 SDK to 14.5, keeping the 13.3 deployment target intact.
NEW_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX14.5.sdk"
OLD_SDK="${CONDA_BUILD_SYSROOT:-}"
if [[ -n "${OLD_SDK}" && "${OLD_SDK}" != "${NEW_SDK}" ]]; then
  for v in CFLAGS CXXFLAGS CPPFLAGS LDFLAGS; do
    val="${!v:-}"
    export "${v}=${val//${OLD_SDK}/${NEW_SDK}}"
  done
fi
export CONDA_BUILD_SYSROOT="${NEW_SDK}"
export SDKROOT="${NEW_SDK}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_OSX_SYSROOT=${NEW_SDK}"

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_OSX_ARCHITECTURES=arm64"
fi

export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PREFIX_PATH=${PREFIX};${SP_DIR} -DPython_EXECUTABLE=$PYTHON -DPython_INCLUDE_DIR=${PREFIX}/include/python${PY_VER}"

$PYTHON -m pip install . -vv --no-deps --no-build-isolation
