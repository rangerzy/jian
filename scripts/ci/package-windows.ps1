param(
    [string]$BuildDir = "build/windows-x64-release"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version Latest

$sourceDir = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$buildPath = (Resolve-Path (Join-Path $sourceDir $BuildDir)).Path
$version = (Get-Content -LiteralPath (Join-Path $buildPath "version.txt") -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Invalid application version: $version"
}

$stageDir = Join-Path $buildPath "package"
$distDir = Join-Path $sourceDir "dist"
if (Test-Path -LiteralPath $stageDir) {
    Remove-Item -LiteralPath $stageDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
cmake --install $buildPath --prefix $stageDir
$payloadDir = Join-Path $stageDir "bin"
$application = Join-Path $payloadDir "jian.exe"
if (-not (Test-Path -LiteralPath $application -PathType Leaf)) {
    throw "CMake did not install $application"
}

# Collect QML imports, Qt plugins, DLLs and the matching MinGW runtime.
windeployqt --release --compiler-runtime --qmldir (Join-Path $sourceDir "qml") $application
@"
[Paths]
Prefix=.
Plugins=.
QmlImports=qml
"@ | Set-Content -LiteralPath (Join-Path $payloadDir "qt.conf") -Encoding utf8
foreach ($required in @("Qt6Core.dll", "Qt6Gui.dll", "Qt6Qml.dll", "Qt6Quick.dll", "platforms/qwindows.dll", "qml/QtQuick/qmldir")) {
    if (-not (Test-Path -LiteralPath (Join-Path $payloadDir $required) -PathType Leaf)) {
        throw "Deployment is missing $required"
    }
}

$compiler = Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6/ISCC.exe"
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    $compiler = (Get-Command ISCC.exe -ErrorAction Stop).Source
}
& $compiler "/DAppVersion=$version" "/DStageDir=$payloadDir" "/DDistDir=$distDir" (Join-Path $sourceDir "packaging/windows/jian.iss")

$installer = Join-Path $distDir "jian-$version-windows-x64-setup.exe"
if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) {
    throw "Installer was not created: $installer"
}
$testDir = Join-Path ([System.IO.Path]::GetTempPath()) ("jian-package-" + [guid]::NewGuid().ToString("N"))
$installedDir = Join-Path $testDir "installed"
New-Item -ItemType Directory -Path $testDir | Out-Null
try {
    $install = Start-Process -FilePath $installer -ArgumentList @(
        "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/SP-",
        "/DIR=`"$installedDir`"", "/LOG=`"$testDir/install.log`""
    ) -PassThru -Wait
    if ($install.ExitCode -ne 0) {
        Get-Content -LiteralPath (Join-Path $testDir "install.log")
        throw "Installer failed with exit code $($install.ExitCode)"
    }

    # Exclude the SDK/toolchain from the child environment and run the installed
    # executable from an unrelated directory, with the native Windows plugin.
    $start = [System.Diagnostics.ProcessStartInfo]::new()
    $start.FileName = Join-Path $installedDir "jian.exe"
    $start.ArgumentList.Add("--smoke-test")
    $start.WorkingDirectory = $testDir
    $start.UseShellExecute = $false
    foreach ($key in @($start.Environment.Keys)) {
        if ($key -match '^(QT|QML|CMAKE_PREFIX_PATH)') {
            $start.Environment.Remove($key) | Out-Null
        }
    }
    $start.Environment["PATH"] = "$env:SystemRoot\System32;$env:SystemRoot"
    $start.Environment["QT_QPA_PLATFORM"] = "windows"
    $start.Environment["QT_QUICK_BACKEND"] = "software"
    $smoke = [System.Diagnostics.Process]::Start($start)
    if (-not $smoke.WaitForExit(30000)) {
        $smoke.Kill($true)
        throw "Installed application did not exit within 30 seconds"
    }
    if ($smoke.ExitCode -ne 0) {
        throw "Installed application failed with exit code $($smoke.ExitCode)"
    }
} finally {
    $uninstaller = Join-Path $installedDir "unins000.exe"
    if (Test-Path -LiteralPath $uninstaller) {
        $uninstall = Start-Process -FilePath $uninstaller -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -PassThru -Wait
        if ($uninstall.ExitCode -ne 0) {
            Write-Warning "Test uninstall returned $($uninstall.ExitCode)"
        }
    }
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
Write-Host "Verified installer: $installer"
