param([Parameter(Mandatory)][string]$Specification,[Parameter(Mandatory)][string]$ToolsetDirectory,[Parameter(Mandatory)][string]$OutputDirectory,[string]$SevenZipPath)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Repository-Common.ps1')
$spec=Read-ComponentSpec $Specification
$source=[IO.Path]::GetFullPath($ToolsetDirectory);$out=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $out){throw 'Use a new candidate output directory.'}
$manifestPath=Join-Path $source 'toolset.json'
$manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
if($manifest.id -cne $spec.id -or $manifest.version -ne $spec.version -or $manifest.host -ne $spec.host -or $manifest.compilerId -cne $spec.compilerId -or
    (Get-FileHash -LiteralPath $manifestPath).Hash -ne $spec.manifestSha256){throw 'Local component does not match the reviewed immutable identity.'}
$name=$spec.id+'-'+$spec.version+'-'+$spec.host+'.mcutoolchain'
& (Join-Path $PSScriptRoot 'New-McuToolchain.ps1') -ToolsetDirectory $source -OutputFile (Join-Path $out $name) -SevenZipPath $SevenZipPath
if((Get-FileHash -LiteralPath $manifestPath).Hash -ne $spec.manifestSha256){throw 'Source manifest changed during packaging.'}
# 7z t 已检查实际归档完整性；读取它记录的展开大小，不再把 7z 当作 ZIP 打开。
$sizes=@(Get-Content -LiteralPath (Join-Path $out ($name+'.packing.log')) | Select-String '^Size:\s*(\d+)\s*$')
if($sizes.Count -ne 1){throw 'Missing or ambiguous 7z unpacked-size receipt.'}
$installedBytes=[long]$sizes[0].Matches[0].Groups[1].Value
$archive=Get-Item -LiteralPath (Join-Path $out $name)
@{formatVersion=1;id=$spec.id;version=$spec.version;host=$spec.host;compilerId=$spec.compilerId;manifestSha256=$spec.manifestSha256;
    asset=$name;sha256=(Get-FileHash -LiteralPath $archive.FullName).Hash.ToLowerInvariant();downloadBytes=$archive.Length;installedBytes=$installedBytes;
    githubAssetFits=($archive.Length -lt 2GB);container='7z';candidate=$true;catalogEligible=$false;publicationStatus=$spec.publication.status}|
    ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $out 'candidate.json') -Encoding utf8
Write-Output (Join-Path $out 'candidate.json')
