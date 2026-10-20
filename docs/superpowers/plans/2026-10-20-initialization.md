# jian Initialization Implementation Plan

> Execute the user-approved initialization in independently verifiable steps.

**Goal:** Create a Qt Quick Hello World project and a working three-platform release pipeline.

**Architecture:** One C++ application entry and one QML window. Platform packaging feeds a shared GitHub Release publisher adapted from xlog_codec.

**Tech Stack:** Qt 6.12, C++20, CMake, Ninja, GitHub Actions, Inno Setup, DMG and Flatpak.

**Spec:** User-confirmed requirements in this conversation on 2026-10-20.

## Constraints

- Project: `jian` / 简, bamboo slips and simplicity.
- Exact slogan: `简，编联而成册`.
- Qt Quick Hello World only. No editor functionality or block-model implementation.
- Development on `dev`; pushes to `main` publish after all three platforms pass.
- Public repository `rangerzy/jian`; first version `0.1.0`.
- Same-version releases replace assets and move the version tag to the verified commit.
- macOS ARM64 DMG, Windows x64 Inno Setup EXE, Linux x64 Flatpak.
- Reference xlog_codec only for GitHub operations, CI and release handling.

## Tasks and checks

- [ ] Create the CMake/Qt Quick project and README. Configure against Qt 6.12, compile, lint QML and run startup smoke verification.
- [ ] Package macOS and Windows with their Qt/QML runtime dependencies. Run the installed application before uploading artifacts.
- [ ] Build Linux inside the Qt-compatible Flatpak SDK. Install the resulting bundle and verify startup.
- [ ] Adapt release publisher and its offline tests for the three native package formats. Preserve digest verification and recovery behavior.
- [ ] Review files and checks, initialize Git on `dev`, create the public remote and publish `main`.
- [ ] Verify three successful Actions jobs and the actual Release assets, then finish on `dev`.

## Review focus

- QML modules must resolve after installation away from the build tree.
- Platform packaging must include or declare required Qt runtime dependencies.
- Qt 6.12 must be selected explicitly instead of an older installed version.
- Partial or outdated builds must not publish an inconsistent set of assets.
- README must distinguish current Hello World scope from the editor's future direction.
