param([Parameter(Mandatory)][string]$ToolsetDirectory, [Parameter(Mandatory)][string]$OutputFile)
$ErrorActionPreference = 'Stop'
$taskSource = [IO.Path]::GetFullPath($ToolsetDirectory)
$taskOutput = [IO.Path]::GetFullPath($OutputFile)
if ([IO.Path]::GetExtension($taskOutput).ToLowerInvariant() -notin @('.mcutoolchain', '.studioxtools')) { throw 'Use .mcutoolchain for development components; existing .studioxtools archives remain supported.' }
if (Test-Path -LiteralPath $taskOutput) { throw 'Archive destination already exists.' }
if ($taskOutput.StartsWith($taskSource.TrimEnd('\')+'\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive must be outside its source tree.' }
$taskManifest = Get-Content -LiteralPath (Join-Path $taskSource 'toolset.json') -Raw | ConvertFrom-Json
if ($taskManifest.formatVersion -ne 1 -or $taskManifest.host -ne 'win-x64') { throw 'Unsupported toolset manifest.' }
if ($taskManifest.id -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$' -or $taskManifest.version -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -or !$taskManifest.compilerId -or !$taskManifest.executables -or !$taskManifest.sha256) { throw 'Development component identity or file index is incomplete.' }
$taskFiles = @(Get-ChildItem -LiteralPath $taskSource -Recurse -Force)
if (@($taskFiles | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count) { throw 'Tool archives do not accept linked files/directories.' }
$taskPayload = @($taskFiles | Where-Object { !$_.PSIsContainer -and $_.FullName -ne (Join-Path $taskSource 'toolset.json') })
if ($taskPayload.Count -ne @($taskManifest.sha256.PSObject.Properties).Count) { throw 'Manifest file set differs from the source tree.' }
foreach ($taskFile in $taskPayload) {
    $taskRelative = [IO.Path]::GetRelativePath($taskSource,$taskFile.FullName).Replace('\','/')
    if ($taskRelative -match '^supra/(.*\/)?license(\.txt|/|$)') { throw 'Private Supra licenses cannot enter distributable archives.' }
    $taskExpected = $taskManifest.sha256.PSObject.Properties[$taskRelative].Value
    if (!$taskExpected -or (Get-FileHash -LiteralPath $taskFile.FullName -Algorithm SHA256).Hash -ne $taskExpected) { throw "Toolset hash mismatch: $taskRelative" }
}
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($taskOutput)) | Out-Null
# 只写文件条目，与现有工具归档安装器的完整文件集合检查一致。
$taskZip = [IO.Compression.ZipFile]::Open($taskOutput,[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($taskFile in $taskFiles | Where-Object { !$_.PSIsContainer }) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($taskZip,$taskFile.FullName,[IO.Path]::GetRelativePath($taskSource,$taskFile.FullName).Replace('\','/'),[IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $taskZip.Dispose() }
Get-FileHash -LiteralPath $taskOutput -Algorithm SHA256
