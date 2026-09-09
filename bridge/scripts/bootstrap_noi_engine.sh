#!/usr/bin/env bash
# Downloads a released noi_engine build to compile/test the preview bridge (bridge/)
# standalone against a real engine version, without waiting on noi_engine's release CI.
# The main noi_engine_editor app has no build-time dependency on noi_engine at all - only
# this bridge does (see bridge/CMakeLists.txt's noi_engine_DIR). Mirrors
# ToolUrlResolver::noiEngineDownloadUrl and PathResolver::noiEngineContentPath so the
# layout matches what a real install (Tools settings tab) produces on disk.
set -euo pipefail

usage() {
    echo "Usage: $0 <version> [target_root]" >&2
    echo "  Installs noi_engine <version> under <target_root>/<version>/noi_engine/{include,libs}" >&2
    echo "  and prints noi_engine_DIR=<content_dir>/libs/cmake/noi_engine for bridge/CMakeLists.txt." >&2
    echo "  Default target_root: \${XDG_DATA_HOME:-\$HOME/.local/share}/noi_engine/noi_engine_editor/tools/noi_engine" >&2
    exit 1
}

[ $# -ge 1 ] || usage
VERSION="$1"
TARGET_ROOT="${2:-${XDG_DATA_HOME:-$HOME/.local/share}/noi_engine/noi_engine_editor/tools/noi_engine}"

case "$(uname -s)" in
    Linux) OS=linux ;;
    Darwin) OS=macos ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64|amd64) ARCH=x64 ;;
    arm64|aarch64) ARCH=arm64 ;;
    *) echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

ASSET="noi_engine-${OS}-${ARCH}-release.zip"
URL="https://github.com/noi-engine/noi_engine_release/releases/download/v${VERSION}/${ASSET}"

VERSION_DIR="${TARGET_ROOT}/${VERSION}"
CONTENT_DIR="${VERSION_DIR}/noi_engine"

if [ -d "${CONTENT_DIR}/include" ] && [ -d "${CONTENT_DIR}/libs" ]; then
    echo "noi_engine ${VERSION} already installed at ${CONTENT_DIR}" >&2
else
    echo "Downloading ${URL}" >&2
    TMP_ZIP="$(mktemp -t noi_engine-XXXXXX.zip)"
    trap 'rm -f "${TMP_ZIP}"' EXIT
    curl -fL "${URL}" -o "${TMP_ZIP}"

    mkdir -p "${VERSION_DIR}"
    unzip -o -q "${TMP_ZIP}" -d "${VERSION_DIR}"
fi

echo "noi_engine_DIR=${CONTENT_DIR}/libs/cmake/noi_engine"
