#!/usr/bin/env bash
# Builds and installs the noi_engine submodule (external/noi_engine) locally so the
# preview bridge (bridge/) can be compiled against local engine sources - for iterating
# on noi_engine and the bridge together without waiting on noi_engine's release CI, and
# without downloading a released build (see bootstrap_noi_engine.sh for that path).
# Mirrors the noi_engine release workflow's build+install step
# (external/noi_engine/.github/workflows/release.yml).
set -euo pipefail

usage() {
    echo "Usage: $0 [build_type] [install_prefix]" >&2
    echo "  build_type: Debug or Release (default: Release)" >&2
    echo "  install_prefix: where to install noi_engine (default: bridge/build/local_noi_engine)" >&2
    echo "  Prints noi_engine_DIR=<install_prefix>/libs/cmake/noi_engine for bridge/CMakeLists.txt." >&2
    exit 1
}

: "${VCPKG_ROOT:?VCPKG_ROOT must be set}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${BRIDGE_DIR}/.." && pwd)"
NOI_ENGINE_SOURCE_DIR="${REPO_ROOT}/external/noi_engine"

BUILD_TYPE="${1:-Release}"
INSTALL_PREFIX="${2:-${BRIDGE_DIR}/build/local_noi_engine}"
BUILD_DIR="${BRIDGE_DIR}/build/local_noi_engine_build"

if [ ! -f "${NOI_ENGINE_SOURCE_DIR}/CMakeLists.txt" ]; then
    echo "external/noi_engine submodule not found/initialized at ${NOI_ENGINE_SOURCE_DIR}" >&2
    echo "Run: git submodule update --init external/noi_engine" >&2
    exit 1
fi

cmake -S "${NOI_ENGINE_SOURCE_DIR}" -B "${BUILD_DIR}" -G Ninja \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
    -DCMAKE_BUILD_SHARED_LIBS=ON \
    -DNOI_ENGINE_BUILD_TESTS=OFF \
    -DNOI_ENGINE_BUILD_SANDBOX=OFF \
    -DCMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"

cmake --build "${BUILD_DIR}"
cmake --install "${BUILD_DIR}" --prefix "${INSTALL_PREFIX}"

echo "noi_engine_DIR=${INSTALL_PREFIX}/libs/cmake/noi_engine"
