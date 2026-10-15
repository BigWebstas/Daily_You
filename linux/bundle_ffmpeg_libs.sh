#!/usr/bin/env bash
#
# Copy the FFmpeg libraries that libfc_native_video_thumbnail_plugin.so was
# linked against (and their dependencies) into the Linux bundle.
#
# The plugin links the build host's FFmpeg (libavformat.so.60 on Ubuntu 24.04).
# Distros with a different FFmpeg, e.g. Arch, cannot resolve those sonames, so
# the app fails to start. Shipping them next to the plugin makes the bundle
# self-contained.
#
# Usage: linux/bundle_ffmpeg_libs.sh <bundle dir>
set -euo pipefail

BUNDLE="${1:?usage: bundle_ffmpeg_libs.sh <bundle dir>}"
LIB="$BUNDLE/lib"
PLUGIN="$LIB/libfc_native_video_thumbnail_plugin.so"

# Libs the host always provides in a compatible version. Bundling these would
# shadow the host's copies (e.g. an older libssl breaking the host's libcurl),
# so only FFmpeg and its codec deps, whose sonames differ per distro, ship.
HOST_LIBS='/(ld-linux[^/]*|libc|libm|libdl|librt|libpthread|libstdc\+\+|libgcc_s|libresolv|libutil|libssl|libcrypto|libgcrypt|libgpg-error|libgnutls|libp11-kit|libtasn1|libidn2|libunistring|libgmp|libglib-2\.0|libgobject-2\.0|libgio-2\.0|libgmodule-2\.0|libgdk_pixbuf-2\.0|libcairo[^/]*|libpango[^/]*|libharfbuzz|libfreetype|libfontconfig|libfribidi|libthai|libdatrie|libgraphite2|libpixman-1|libpng16|libX[^/]*|libxcb[^/]*|libdrm|libva[^/]*|libvdpau|libz|libbz2|liblzma|libffi|libpcre2-8|libexpat|libselinux|libmount|libblkid|libbsd|libmd|libkrb5[^/]*|libgssapi_krb5|libk5crypto|libcom_err|libkeyutils|libOpenCL|libgomp)\.so'

# Closure of the plugin's libav* deps, minus the host libs.
ldd "$PLUGIN" | awk '/=> \//{print $3}' \
  | grep -E '/libav|/libsw' | while read -r so; do
  ldd "$so" | awk '/=> \//{print $3}'
  echo "$so"
done | sort -u \
  | grep -Ev "$HOST_LIBS" \
  | while read -r so; do
  cp -L "$so" "$LIB/"
done

# Dependents resolve siblings via their own RUNPATH, not the executable's.
for so in "$PLUGIN" "$LIB"/lib*.so*; do
  case "$(basename "$so")" in libflutter_linux_gtk.so|libapp.so) continue;; esac
  patchelf --set-rpath '$ORIGIN' "$so"
done
