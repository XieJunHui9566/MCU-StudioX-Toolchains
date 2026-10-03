#!/bin/bash
set -euo pipefail
# 所有路径由调用方传入，构建只使用隔离目录和指定的开发环境组件。
: "${SOURCE_ROOT:?Set SOURCE_ROOT to the pinned Icarus source directory}"
: "${BUILD_ROOT:?Set BUILD_ROOT to a new build directory}"
: "${OUTPUT_PREFIX:?Set OUTPUT_PREFIX to a new install directory}"
: "${MINGW_BIN:?Set MINGW_BIN to verified pc.mingw/1.0.0 gcc/bin}"
export PATH="$MINGW_BIN:/usr/bin:/bin"
export CC=gcc CXX=g++ AR=ar RANLIB=ranlib
cd "$SOURCE_ROOT"
sh autoconf.sh
mkdir -p "$BUILD_ROOT"
cd "$BUILD_ROOT"
"$SOURCE_ROOT/configure" --host=x86_64-w64-mingw32 --prefix="$OUTPUT_PREFIX" LDFLAGS="-static-libgcc -static-libstdc++"
make -j4
make install
find "$OUTPUT_PREFIX" -type f \( -name '*.exe' -o -name '*.dll' -o -name '*.vpi' -o -name '*.tgt' \) -exec strip --strip-debug '{}' +
