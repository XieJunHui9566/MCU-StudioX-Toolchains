param(
    [Parameter(Mandatory)][string]$SdccInstaller,
    [Parameter(Mandatory)][string]$CMakeArchive,
    [Parameter(Mandatory)][string]$NinjaArchive,
    [Parameter(Mandatory)][string]$NoticesDirectory,
    [Parameter(Mandatory)][string]$SevenZipExecutable,
    [Parameter(Mandatory)][string]$ScratchDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$inputs = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'upstream-files.json') -Raw | ConvertFrom-Json
$paths = @{ sdcc = $SdccInstaller; cmake = $CMakeArchive; ninja = $NinjaArchive }
foreach ($item in $inputs.archives) {
    $file = Get-Item -LiteralPath $paths[$item.role]
    if ($file.Length -ne $item.bytes -or (Get-FileHash -LiteralPath $file.FullName).Hash -ne $item.sha256) {
        throw "Official archive does not match the reviewed bytes: $($item.role)"
    }
}
foreach ($item in $inputs.notices) {
    if ((Get-FileHash -LiteralPath (Join-Path $NoticesDirectory $item.file)).Hash -ne $item.sha256) {
        throw "Notice does not match the reviewed bytes: $($item.file)"
    }
}
$scratch = [IO.Path]::GetFullPath($ScratchDirectory)
$output = [IO.Path]::GetFullPath($OutputDirectory)
if ((Test-Path -LiteralPath $scratch) -or (Test-Path -LiteralPath $output)) { throw 'Use new scratch and output directories.' }
[IO.Directory]::CreateDirectory($scratch) | Out-Null
& $SevenZipExecutable x $SdccInstaller ("-o" + (Join-Path $scratch 'sdcc')) -y -bso0 -bsp0
if ($LASTEXITCODE -ne 0) { throw 'Cannot extract the pinned official SDCC installer.' }
Expand-Archive -LiteralPath $CMakeArchive -DestinationPath (Join-Path $scratch 'cmake')
Expand-Archive -LiteralPath $NinjaArchive -DestinationPath (Join-Path $scratch 'ninja')
function Copy-Tree([string]$Source, [string]$Destination, [string[]]$Exclude = @()) {
    foreach ($file in Get-ChildItem -LiteralPath $Source -Recurse -Force) {
        if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked source assets are not accepted.' }
        if ($file.PSIsContainer) { continue }
        $relative = [IO.Path]::GetRelativePath($Source, $file.FullName).Replace('\', '/')
        if ($relative -in $Exclude) { continue }
        $target = Join-Path $Destination $relative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
        [IO.File]::Copy($file.FullName, $target, $false)
    }
}
# 编译工具只从官方归档的白名单提取；本机安装目录及其中的备份、厂商头文件不参与打包。
foreach ($item in $inputs.sdccPrograms) {
    $source = Join-Path $scratch ('sdcc/bin/' + $item.file)
    if ((Get-FileHash -LiteralPath $source).Hash -ne $item.sha256) { throw 'SDCC program bytes differ from the reviewed official distribution.' }
    $destination = Join-Path $output ('sdcc/bin/' + $item.file)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    [IO.File]::Copy($source, $destination, $false)
}
foreach ($part in @('doc', 'include', 'lib')) { Copy-Tree (Join-Path $scratch ('sdcc/' + $part)) (Join-Path $output ('sdcc/' + $part)) }
foreach ($name in @('COPYING.txt', 'COPYING3.txt')) { [IO.File]::Copy((Join-Path $scratch ('sdcc/' + $name)), (Join-Path $output ('sdcc/' + $name)), $false) }
# IDE 使用 CMake 命令行；不携带 Qt GUI 二进制，以免加入与编译流程无关的运行时及其交付要求。
Copy-Tree (Join-Path $scratch 'cmake/cmake-4.4.0-windows-x86_64') (Join-Path $output 'cmake') @('bin/cmake-gui.exe')
Copy-Tree (Join-Path $scratch 'ninja') (Join-Path $output 'ninja')
foreach ($item in $inputs.notices) {
    $destination = Join-Path $output ('licenses/' + $item.file)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    [IO.File]::Copy((Join-Path $NoticesDirectory $item.file), $destination, $false)
}
$roles = [ordered]@{sdcc='sdcc/bin/sdcc.exe';sdar='sdcc/bin/sdar.exe';sdas8051='sdcc/bin/sdas8051.exe';sdld='sdcc/bin/sdld.exe';sdobjcopy='sdcc/bin/sdobjcopy.exe';packihx='sdcc/bin/packihx.exe';makebin='sdcc/bin/makebin.exe';cmake='cmake/bin/cmake.exe';ninja='ninja/ninja.exe'}
$provenance = [ordered]@{formatVersion=1;recipe='recipes/stc.sdcc/1.0.1/Prepare-Toolset.ps1';upstreamArchives=$inputs.archives;scope='MCS-51 build tools, official standard headers and libraries, CLI CMake and Ninja';notes='Official bytes retained for included programs. No local STC vendor headers, backups, non-free PIC tree, debugger, simulator, standalone runtime DLLs or CMake GUI. No hardware validation.'}
function Write-Json([string]$Path, $Value) { [IO.File]::WriteAllText($Path, (($Value | ConvertTo-Json -Depth 10).Replace("`r`n", "`n") + "`n"), [Text.UTF8Encoding]::new($false)) }
Write-Json (Join-Path $output 'provenance.json') $provenance
$hashes = [ordered]@{}
foreach ($file in Get-ChildItem -LiteralPath $output -File -Recurse | Sort-Object FullName) {
    $relative = [IO.Path]::GetRelativePath($output, $file.FullName).Replace('\', '/')
    $hashes[$relative] = (Get-FileHash -LiteralPath $file.FullName).Hash.ToLowerInvariant()
}
Write-Json (Join-Path $output 'toolset.json') ([ordered]@{formatVersion=1;id='stc.sdcc';version='1.0.1';host='win-x64';compilerId='sdcc-4.5.0-15242';displayName='STC 8-bit / SDCC';componentVersions=[ordered]@{sdcc='SDCC 4.5.0 #15242 (MINGW64)';cmake='cmake version 4.4.0';ninja='1.10.2'};executables=$roles;sha256=$hashes})
Write-Output "Prepared stc.sdcc/1.0.1 in $output; $($hashes.Count) indexed files."
