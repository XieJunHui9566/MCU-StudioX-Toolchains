param([Parameter(Mandatory)][string]$OfficialArchive,
    [Parameter(Mandatory)][string]$SevenZipExecutable,
    [Parameter(Mandatory)][string]$ScratchDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
$inputs=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'inputs.json') -Raw | ConvertFrom-Json
$manifestPath=Join-Path $PSScriptRoot 'toolset.json'
$manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if((Get-Item -LiteralPath $OfficialArchive).Length -ne $inputs.archive.bytes -or
    (Get-FileHash -LiteralPath $OfficialArchive).Hash -ne $inputs.archive.sha256 -or
    (Get-FileHash -LiteralPath $manifestPath).Hash -ne $inputs.manifestSha256){throw 'Pinned upstream archive or original manifest differs.'}
$scratch=[IO.Path]::GetFullPath($ScratchDirectory)
$output=[IO.Path]::GetFullPath($OutputDirectory)
if((Test-Path -LiteralPath $scratch) -or (Test-Path -LiteralPath $output)){throw 'Use new scratch and output directories.'}
[IO.Directory]::CreateDirectory($scratch)|Out-Null
& $SevenZipExecutable x $OfficialArchive ('-o'+$scratch) -y -bso0 -bsp0
if($LASTEXITCODE -ne 0){throw 'Cannot extract pinned upstream archive.'}
foreach($entry in $manifest.sha256.psobject.Properties){
    $relative=$entry.Name
    if($relative -match '(^|[\\/])\.\.([\\/]|$)|:|^[\\/]'){throw 'Invalid manifest path.'}
    $source=if($relative.StartsWith('gcc/')){Join-Path $scratch ('mingw64/'+$relative.Substring(4))}else{Join-Path $PSScriptRoot ('overlays/'+$relative)}
    $item=Get-Item -LiteralPath $source
    if($item.Attributes -band [IO.FileAttributes]::ReparsePoint -or $item.PSIsContainer -or
        (Get-FileHash -LiteralPath $source).Hash -ne $entry.Value){throw ('Upstream file differs: '+$relative)}
    $target=Join-Path $output $relative
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))|Out-Null
    [IO.File]::Copy($source,$target,$false)
}
# 保留原始清单字节，恢复后的组件仍能满足已有工程的内容锁。
[IO.File]::Copy($manifestPath,(Join-Path $output 'toolset.json'),$false)
Write-Output ('Prepared pc.mingw/1.0.0 with '+@($manifest.sha256.psobject.Properties).Count+' pinned files.')
