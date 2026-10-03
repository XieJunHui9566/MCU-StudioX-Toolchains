param([Parameter(Mandatory)][string]$Specification,[Parameter(Mandatory)][string]$ToolsetDirectory,[Parameter(Mandatory)][string]$OutputDirectory)
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
& (Join-Path $PSScriptRoot 'New-McuToolchain.ps1') -ToolsetDirectory $source -OutputFile (Join-Path $out $name)
if((Get-FileHash -LiteralPath $manifestPath).Hash -ne $spec.manifestSha256){throw 'Source manifest changed during packaging.'}
$zip=[IO.Compression.ZipFile]::OpenRead((Join-Path $out $name))
try{$installedBytes=[long](($zip.Entries|Measure-Object Length -Sum).Sum)}finally{$zip.Dispose()}
$archive=Get-Item -LiteralPath (Join-Path $out $name)
@{formatVersion=1;id=$spec.id;version=$spec.version;host=$spec.host;compilerId=$spec.compilerId;manifestSha256=$spec.manifestSha256;
    asset=$name;sha256=(Get-FileHash -LiteralPath $archive.FullName).Hash.ToLowerInvariant();downloadBytes=$archive.Length;installedBytes=$installedBytes;
    githubAssetFits=($archive.Length -lt 2GB);candidate=$true;catalogEligible=$false;publicationStatus=$spec.publication.status}|
    ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $out 'candidate.json') -Encoding utf8
Write-Output (Join-Path $out 'candidate.json')
