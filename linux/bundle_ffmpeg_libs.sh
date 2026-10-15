#!/usr/bin/env bash
#
# Copy the FFmpeg libraries that libfc_native_video_thumbnail_plugin.so was
# linked against (and their dependencies) into the Linux bundle.
#
# The plugin links the build host's FFmpeg (libavformat.so.60 on Ubuntu 24.04).
# Distros with a different FFmpeg, e.g. Arch, cannot resolve those sonames, so
# the app fails to start. Shipping them next to the plugin makes the bundle
# self-contained. Core glibc/compiler runtime libs stay on the host.
#
# Usage: linux/bundle_ffmpeg_libs.sh <bundle dir>
set -euo pipefail

BUNDLE="${1:?usage: bundle_ffmpeg_libs.sh <bundle dir>}"
LIB="$BUNDLE/lib"
PLUGIN="$LIB/libfc_native_video_thumbnail_plugin.so"

# Closure of the plugin's libav* deps, minus the base system libs.
ldd "$PLUGIN" | awk '/=> \//{print $3}' \
  | grep -E '/libav|/libsw' | while read -r so; do
  ldd "$so" | awk '/=> \//{print $3}'
  echo "$so"
done | sort -u \
  | grep -Ev '/(ld-linux[^/]*|libc|libm|libdl|librt|libpthread|libstdc\+\+|libgcc_s|libresolv|libutil)\.so' \
  | while read -r so; do
  cp -L "$so" "$LIB/"
done

# Dependents resolve siblings via their own RUNPATH, not the executable's.
for so in "$PLUGIN" "$LIB"/lib*.so*; do
  case "$(basename "$so")" in libflutter_linux_gtk.so|libapp.so) continue;; esac
  patchelf --set-rpath '$ORIGIN' "$so"
done
