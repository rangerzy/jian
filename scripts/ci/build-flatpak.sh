#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$project_dir"

if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
    echo "This package must be built on Linux x86_64." >&2
    exit 1
fi

for command in flatpak flatpak-builder python3 desktop-file-validate dbus-run-session xvfb-run timeout eu-strip eu-elfcompress; do
    command -v "$command" >/dev/null || {
        echo "Required command not found: $command" >&2
        exit 1
    }
done

version="$(python3 - <<'PY'
import pathlib
import re

source = pathlib.Path("CMakeLists.txt").read_text(encoding="utf-8")
match = re.search(
    r"(?m)^\s*project\(\s*jian\s+VERSION\s+([0-9]+\.[0-9]+\.[0-9]+)\s+LANGUAGES\s+CXX\s*\)",
    source,
)
if not match:
    raise SystemExit("Cannot read the project version from CMakeLists.txt")
print(match.group(1))
PY
)"

app_id=io.github.rangerzy.jian
runtime_branch=6.12-beta
runtime_repo=https://flathub.org/beta-repo/flathub-beta.flatpakrepo
manifest=packaging/linux/io.github.rangerzy.jian.json
build_dir=build/flatpak
repo_dir=build/flatpak-repo
bundle="dist/jian-${version}-linux-x64.flatpak"

# KDE currently publishes Qt 6.12 in Flathub Beta. Keep this explicit until
# its stable runtime is available; never silently fall back to an older Qt.
flatpak remote-add --user --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists flathub-beta "$runtime_repo"
flatpak install --user --noninteractive flathub-beta \
    "org.kde.Platform/x86_64/$runtime_branch" \
    "org.kde.Sdk/x86_64/$runtime_branch"

qt_version="$(flatpak run --user --arch=x86_64 --command=pkg-config \
    "org.kde.Sdk//$runtime_branch" --modversion Qt6Core)"
if [[ ! "$qt_version" =~ ^6\.12\.[0-9]+$ ]]; then
    echo "Expected released Qt 6.12.x in the SDK; found: $qt_version" >&2
    exit 1
fi
echo "Building Jian $version with Qt $qt_version (KDE $runtime_branch)."

desktop-file-validate "packaging/linux/$app_id.desktop"
mkdir -p build dist
flatpak-builder --user --arch=x86_64 --force-clean \
    --disable-rofiles-fuse --rebuild-on-sdk-change \
    --repo="$repo_dir" "$build_dir" "$manifest"

test -x "$build_dir/files/bin/jian"
test -f "$build_dir/files/share/applications/$app_id.desktop"
test -f "$build_dir/files/share/icons/hicolor/scalable/apps/$app_id.svg"
flatpak build-bundle --arch=x86_64 --runtime-repo="$runtime_repo" \
    "$repo_dir" "$bundle" "$app_id" stable

# Exercise the exported artifact, including its installed QML imports.
flatpak install --user --noninteractive --reinstall "$bundle"
timeout 30s dbus-run-session -- xvfb-run -a \
    flatpak run --user --arch=x86_64 \
    --env=QT_QPA_PLATFORM=xcb --env=QT_QUICK_BACKEND=software \
    "$app_id//stable" --smoke-test

test -s "$bundle"
echo "Verified Flatpak bundle: $bundle"
