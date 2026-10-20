#!/usr/bin/env bash
set -euo pipefail

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_dir="${1:-$source_dir/build/macos-arm64-release}"
build_dir="$(cd "$build_dir" && pwd)"
version="$(tr -d '\r\n' < "$build_dir/version.txt")"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid application version: $version" >&2
    exit 1
fi

# Stage outside the checkout: synced Documents folders can reattach Finder
# metadata while codesign is sealing an application bundle.
package_root="$(mktemp -d "${TMPDIR:-/tmp}/jian-package.XXXXXX")"
stage_dir="$package_root/payload"
test_dir="$package_root/test"
mount_dir="$package_root/mounted"
mounted=false
cleanup() {
    if [[ "$mounted" == true ]]; then
        hdiutil detach "$mount_dir" -quiet || true
    fi
    rm -rf "$package_root"
}
trap cleanup EXIT
dist_dir="$source_dir/dist"
mkdir -p "$stage_dir" "$dist_dir"
cmake --install "$build_dir" --prefix "$stage_dir"
app="$stage_dir/jian.app"
test -x "$app/Contents/MacOS/jian"
test "$(lipo -archs "$app/Contents/MacOS/jian")" = arm64

# CMake's Qt QML deployment script installs only scanned modules and invokes
# macdeployqt for their runtime dependencies. A direct -qmldir deployment also
# recursively copies unrelated modules nested below QtQuick.
test -d "$app/Contents/Frameworks/QtCore.framework"
test -f "$app/Contents/PlugIns/platforms/libqcocoa.dylib"
test -f "$app/Contents/Resources/qml/QtQuick/qmldir"

# Framework copies can carry Finder metadata, which codesign rejects. Clean the
# staged bundle only, then sign its nested code before signing the app itself.
xattr -cr "$app"
while IFS= read -r -d '' library; do
    codesign --force --sign - "$library"
done < <(find "$app/Contents" -type f -name '*.dylib' -print0)
while IFS= read -r -d '' framework; do
    codesign --force --sign - "$framework"
done < <(find "$app/Contents/Frameworks" -depth -type d -name '*.framework' -print0)
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
ln -s /Applications "$stage_dir/Applications"

dmg="$dist_dir/jian-$version-macos-arm64.dmg"
hdiutil create -volname jian -srcfolder "$stage_dir" -ov -format UDZO "$dmg"
hdiutil verify "$dmg"

mkdir -p "$mount_dir" "$test_dir/installed"
hdiutil attach "$dmg" -readonly -nobrowse -mountpoint "$mount_dir" -quiet
mounted=true
ditto "$mount_dir/jian.app" "$test_dir/installed/jian.app"
hdiutil detach "$mount_dir" -quiet
mounted=false
codesign --verify --deep --strict "$test_dir/installed/jian.app"

# A clean environment prevents Qt/QML paths from the development installation
# from hiding a missing deployment dependency. Exercise the native Cocoa plugin.
python3 - "$test_dir/installed/jian.app/Contents/MacOS/jian" "$test_dir" <<'PY'
import os
import subprocess
import sys

environment = {
    "HOME": os.environ["HOME"],
    "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
    "TMPDIR": os.environ.get("TMPDIR", "/tmp"),
    "QT_QPA_PLATFORM": "cocoa",
    "QT_QUICK_BACKEND": "software",
}
subprocess.run(
    [sys.argv[1], "--smoke-test"],
    cwd=sys.argv[2],
    env=environment,
    timeout=30,
    check=True,
)
PY
echo "Verified disk image: $dmg"
