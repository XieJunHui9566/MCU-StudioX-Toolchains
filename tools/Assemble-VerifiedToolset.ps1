param([Parameter(Mandatory)][string]$RecipeDirectory,[Parameter(Mandatory)][string]$InputsDirectory,
    [Parameter(Mandatory)][string]$SevenZipExecutable,[Parameter(Mandatory)][string]$ScratchDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
$manifestPath=Join-Path $RecipeDirectory 'toolset.json'
$inputs=Get-Content -LiteralPath (Join-Path $RecipeDirectory 'inputs.json') -Raw | ConvertFrom-Json
$manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if((Get-FileHash -LiteralPath $manifestPath).Hash -ne $inputs.manifestSha256){throw 'Recipe manifest changed.'}
$scratch=[IO.Path]::GetFullPath($ScratchDirectory)
$output=[IO.Path]::GetFullPath($OutputDirectory)
if((Test-Path -LiteralPath $scratch) -or (Test-Path -LiteralPath $output)){throw 'Use new scratch and output directories.'}
function Safe-Relative([string]$value){
    if(!$value -or $value -match '(^|[\\/])\.\.([\\/]|$)|:|^[\\/]'){throw 'Unsafe recipe path.'}
    return $value
}
foreach($inputRecord in $inputs.archives){
    $file=Join-Path $InputsDirectory (Safe-Relative $inputRecord.file)
    if((Get-Item -LiteralPath $file).Length -ne $inputRecord.bytes -or
       (Get-FileHash -LiteralPath $file).Hash -ne $inputRecord.sha256){throw ('Upstream input differs: '+$inputRecord.file)}
    $extract=Join-Path $scratch (Safe-Relative $inputRecord.group)
    [IO.Directory]::CreateDirectory($extract)|Out-Null
    & $SevenZipExecutable x $file ('-o'+$extract) -y -bso0 -bsp0
    if($LASTEXITCODE -ne 0){throw ('Cannot extract '+$inputRecord.file)}
}
foreach($entry in $manifest.sha256.psobject.Properties){
    $relative=Safe-Relative $entry.Name
    $group=$relative.Split('/')[0]
    $archive=@($inputs.archives|Where-Object {$_.group -ceq $group})
    if($archive.Count -gt 1){throw 'Duplicate recipe group.'}
    if($archive.Count -eq 1){
        $suffix=$archive[0].prefix+$relative.Substring($group.Length+1)
        $source=Join-Path (Join-Path $scratch $group) (Safe-Relative $suffix)
    }else{$source=Join-Path (Join-Path $RecipeDirectory 'overlays') $relative}
    $item=Get-Item -LiteralPath $source
    if($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
       (Get-FileHash -LiteralPath $source).Hash -ne $entry.Value){throw ('Payload differs: '+$relative)}
    $target=Join-Path $output $relative
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))|Out-Null
    [IO.File]::Copy($source,$target,$false)
}
# 清单字节参与工程内容锁；组装不得格式化或替换该文件。
[IO.File]::Copy($manifestPath,(Join-Path $output 'toolset.json'),$false)
Write-Output ('Prepared '+$manifest.id+'/'+$manifest.version+' with '+@($manifest.sha256.psobject.Properties).Count+' verified files.')
