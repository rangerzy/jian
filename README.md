# 简 · jian

**简，编联而成册**

竹简，单片为简，编联成册。

一个「简」字，既是**竹简之简**，也是**简洁之简**。
片片相联、渐成一册，也藏着未来编辑器的块模型理念。

jian 是一个基于 **Qt 6.12** 的 Markdown 编辑器项目，主打 **Qt 自绘、快、简单**。

## 当前阶段

版本：`0.1.0`。

当前仅初始化 **Qt Quick Hello World 工程**：一个窗口，显示 `Hello World` 和「简，编联而成册」。
Markdown 编辑、文件操作、块模型与自绘编辑器均尚未实现，具体技术路线留待后续开发。

本项目只参考 `xlog_codec` 的 GitHub 操作、三端 Actions 和 Release 配置。

## 开发环境

- Qt **6.12**，需要 Qt Quick；CI 的 macOS/Windows 使用 `6.12.0`。
- C++20 编译器。
- CMake **3.24+**、Ninja。
- macOS 使用 Apple Clang；Windows 使用 Qt 配套的 MinGW x64；Linux 使用 GCC。

Qt 安装路径由 `CMAKE_PREFIX_PATH` 指定，不写入机器专属路径。
本机同时安装多个 Qt 版本时，请明确选择 6.12。

### macOS ARM64

```sh
cmake --preset macos-arm64-release \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.12.0/macos"
cmake --build --preset macos-arm64-release
ctest --preset macos-arm64-release
open build/macos-arm64-release/jian.app
```

macOS 最低部署目标为 **14.4**。

### Windows x64

在已经配置好 Qt 6.12 和配套 MinGW 的终端中执行：

```powershell
cmake --preset windows-x64-release -DCMAKE_PREFIX_PATH="$env:QTDIR"
cmake --build --preset windows-x64-release
ctest --preset windows-x64-release
.\build\windows-x64-release\jian.exe
```

`QTDIR` 指向 Qt 的 MinGW 安装目录；Qt 与 MinGW 的 `bin` 目录需要位于 `PATH`。

### Linux

本地已安装 Qt 6.12 开发环境时：

```sh
cmake --preset linux-x64-release -DCMAKE_PREFIX_PATH="$QTDIR"
cmake --build --preset linux-x64-release
ctest --preset linux-x64-release
./build/linux-x64-release/jian
```

发布包使用 Flatpak，在 KDE SDK 内构建，用户不需要单独安装宿主机 Qt。
Qt 6.12 对应的 KDE 运行时目前来自 **flathub-beta 的 `6.12-beta` 分支**；
这是初始化阶段的运行时依赖，后续可在稳定分支可用后迁移。

### Debug 与验证

```sh
cmake --preset debug -DCMAKE_PREFIX_PATH="/path/to/Qt/6.12.0/platform"
cmake --build --preset debug
ctest --preset debug
cmake --build --preset debug --target jian_qmllint
python3 -B -m unittest discover -s tests -v
```

CTest 通过 `--smoke-test` 检查实际 Qt Quick 启动路径，加载 QML 后自动退出；
QML 加载失败返回非零。发布脚本的 Python 测试无需网络或 GitHub 凭据。

## 三端发布

[GitHub Releases](https://github.com/rangerzy/jian/releases) 提供以下产物：

| 平台 | 文件 | 内容 |
| --- | --- | --- |
| macOS ARM64 | `jian-0.1.0-macos-arm64.dmg` | 包含 Qt/QML 依赖的 `.app` |
| Windows x64 | `jian-0.1.0-windows-x64-setup.exe` | Inno Setup 安装包，包含 Qt/QML 与编译器运行库 |
| Linux x64 | `jian-0.1.0-linux-x64.flatpak` | Flatpak 单文件应用包，依赖 KDE 6.12-beta 运行时 |

macOS 与 Windows 初始产物尚未配置开发者证书签名，macOS 也未配置 Apple 公证。
Linux 产物由 GitHub Release 分发，目前未提交到 Flathub 应用目录。

本地打包入口（先完成对应平台的 Release 构建，并将 Qt `bin` 加入 `PATH`）：

```sh
# macOS
bash packaging/macos/package.sh

# Windows PowerShell，需安装 Inno Setup 6
./scripts/ci/package-windows.ps1

# Linux，依赖与安装命令见 packaging/linux/README.md
bash scripts/ci/build-flatpak.sh
```

三个打包入口都会验证最终安装产物的启动。Linux 的构建和下载包安装步骤见
[Flatpak 说明](packaging/linux/README.md)。

## 分支与发布规则

日常开发使用 **`dev`**，**推送 `main` 表示发布**。

```sh
git switch dev
# 开发、验证、提交
git push origin dev

# 准备发布
git switch main
git pull --ff-only origin main
git merge --ff-only dev
git push origin main
git switch dev
```

- 推送 `dev` 不触发发布工作流。
- 向 `main` 提交 PR：构建、验证、打包三端，验证发布脚本，不发布 Release。
- 推送 `main` 或在 `main` 手动运行工作流：三端全部成功后自动发布。
- 默认工作流权限为 `contents: read`，只有发布任务使用 `contents: write`。

版本唯一来源为 `CMakeLists.txt` 的 `project(jian VERSION ...)`。
Release 标签为 `v<版本>`，标题为 `jian <版本>`。

**同版本会更新同一个 Release、替换三个附件，并将标签移动到最新成功发布的提交。**
因此，同版本的下载内容可能随再次发布而变化；需要新版本记录时，修改项目版本号。

发布先进入草稿状态，三个附件上传并通过 SHA-256 校验后才正式发布。
发布说明包含提交 SHA、主题、作者、日期、工作流链接，以及同版本两次发布之间的提交。
同版本的旧提交不会覆盖较新的发布，中断后可重跑恢复。

## 工程结构

```text
CMakeLists.txt             # 项目、版本、Qt Quick 模块与安装
CMakePresets.json          # 本地三端构建预设
src/main.cpp              # 应用入口
qml/Main.qml              # Hello World 窗口与 slogan
packaging/                # Inno Setup、DMG、Flatpak 配置
.github/workflows/        # 三端构建与发布
.github/scripts/          # Release 发布脚本
tests/                    # 发布脚本离线测试
```
