#!/usr/bin/env bash
#
# Package a Daily You AppImage from a completed `flutter build linux --release`.
#
# appimage-builder bundles the app and its libraries fine, but the runtime it
# embeds is the old AppImageKit one, which dlopen()s libfuse.so.2. That library
# is not installed by default on Arch or on Ubuntu 24.04+, so the AppImage fails
# to start with "dlopen(): error loading libfuse.so.2".
#
# Fix: let appimage-builder build only the AppDir, then pack it ourselves with
# the statically linked "type2" runtime, which carries its own libfuse and only
# needs fusermount (present on Arch and modern Ubuntu).
#
# Usage: linux/package_appimage.sh <version>
set -euo pipefail

VERSION="${1:?usage: package_appimage.sh <version>}"
export APP_VERSION="$VERSION"
OUT="DailyYou-${VERSION}-x86_64.AppImage"

RUNTIME_URL="https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64"
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"

# 1. Build the AppDir only (no final AppImage, no docker tests).
appimage-builder --recipe AppImageBuilder.yml --skip-tests --skip-appimage

# 2. Fetch the FUSE-less runtime and a current appimagetool.
curl -fsSL -o runtime-x86_64 "$RUNTIME_URL"
curl -fsSL -o appimagetool "$APPIMAGETOOL_URL"
chmod +x appimagetool

# 3. Pack the AppDir with that runtime. --appimage-extract-and-run lets
#    appimagetool (itself an AppImage) run on a host without libfuse2.
ARCH=x86_64 ./appimagetool --appimage-extract-and-run \
  --runtime-file runtime-x86_64 \
  AppDir "$OUT"

echo "Built $OUT"
