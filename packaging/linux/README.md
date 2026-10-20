# Linux Flatpak

The initial package targets Linux x86_64 and uses the app ID
`io.github.rangerzy.jian`. Its manifest builds the checked-out project with the
KDE SDK. No Qt installation is needed on the host.

## Runtime choice

As verified on 2026-10-20, KDE's Qt 6.12 runtime is published on **Flathub Beta**
as `org.kde.Platform//6.12-beta` and `org.kde.Sdk//6.12-beta`. The runtime contains
released Qt 6.12.0, but the runtime distribution itself is still beta. The
stable `6.12` runtime was not available when this configuration was prepared.

The build script checks that the SDK reports a released Qt 6.12.x version and
fails if it does not. Qt 6.12 patch updates are allowed. The application still
requires Qt 6.12 or newer in CMake; this package does not fall back to older Qt.
When KDE publishes the stable runtime, update the manifest, script, and install
instructions together after verifying the new branch.

Evidence:

- [KDE's Qt 6.12 runtime recipe at the checked revision](https://github.com/KDE/flatpak-kde-runtime/blob/8123e682793f8ded9a64702a7cdc68fe8f26e329/org.kde.Sdk.json.in)
  specifies branch `6.12-beta` and Qt 6.12.0 sources.
- [Published x86_64 platform ref](https://dl.flathub.org/beta-repo/refs/heads/runtime/org.kde.Platform/x86_64/6.12-beta)
  and [SDK ref](https://dl.flathub.org/beta-repo/refs/heads/runtime/org.kde.Sdk/x86_64/6.12-beta)
  confirm both packages are available.
- [Flatpak's single-file bundle documentation](https://docs.flatpak.org/en/latest/single-file-bundles.html)
  describes bundling and the runtime repository hint.

## Build and verify

On Ubuntu 24.04 x86_64:

```sh
sudo apt-get update
sudo apt-get install -y flatpak flatpak-builder python3 desktop-file-utils \
  dbus-x11 xvfb xauth coreutils
bash scripts/ci/build-flatpak.sh
```

The script adds Flathub and Flathub Beta to the current user's Flatpak remotes,
installs the SDK/runtime, builds from the local project root, and creates
`dist/jian-<version>-linux-x64.flatpak`. The version comes from `project(... VERSION ...)`
in `CMakeLists.txt`. It then installs that bundle for the current user and runs
`--smoke-test` under Xvfb with software rendering. The smoke test must load the
QML window and exit successfully within 30 seconds.

Only display, shared memory, and graphics device permissions are requested.
No network or home-directory permission is granted.

## Install the downloaded bundle

The bundle contains the application. Its runtime is downloaded separately:

```sh
flatpak remote-add --user --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists flathub-beta \
  https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak install --user flathub-beta org.kde.Platform//6.12-beta
flatpak install --user ./jian-0.1.0-linux-x64.flatpak
flatpak run io.github.rangerzy.jian
```

This is a standalone GitHub Release bundle, not a Flathub app submission. AppStream
catalog metadata is intentionally absent until the project license and product
metadata have been chosen. The SVG is a generic application-window placeholder
for project initialization, not a finished logo.
