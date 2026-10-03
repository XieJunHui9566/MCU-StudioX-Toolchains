param([Parameter(Mandatory)][string]$Specification,[Parameter(Mandatory)][string]$CandidateDirectory,
    [Parameter(Mandatory)][string]$ValidationFile,[Parameter(Mandatory)][string]$SourceMaterialsDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory,[string]$Repository='XieJunHui9566/MCU-StudioX-Toolchains')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Repository-Common.ps1')
$root=Split-Path -Parent $PSScriptRoot
$spec=Read-ComponentSpec $Specification
$candidate=Get-Content -LiteralPath (Join-Path $CandidateDirectory 'candidate.json') -Raw|ConvertFrom-Json
$validation=Get-Content -LiteralPath $ValidationFile -Raw|ConvertFrom-Json
$release=[ordered]@{formatVersion=1;id=$candidate.id;version=$candidate.version;host=$candidate.host;compilerId=$candidate.compilerId;
    manifestSha256=$candidate.manifestSha256;tag=($spec.id+'-'+$spec.version+'-'+$spec.host);asset=$candidate.asset;sha256=$candidate.sha256;
    downloadBytes=$candidate.downloadBytes;installedBytes=$candidate.installedBytes;published=$true;
    reviewEvidenceSha256=$spec.publication.reviewEvidence.sha256;
    validation=@{status=$validation.status;scope=$validation.scope;archiveSha256=$validation.archiveSha256;manifestSha256=$validation.manifestSha256;evidenceSha256=(Get-FileHash -LiteralPath $ValidationFile).Hash.ToLowerInvariant()};sourceAssets=@()}
foreach($item in $spec.publication.sourceAssets){
    $release.sourceAssets+=@{file=$item.file;sha256=$item.sha256;bytes=$item.bytes;url=('https://github.com/'+$Repository+'/releases/download/'+$release.tag+'/'+$item.file)}
}
$null=Get-PublishedCatalogEntry $spec $release $Repository
$archive=Resolve-RepositoryFile $CandidateDirectory $candidate.asset
if((Get-Item -LiteralPath $archive).Length -ne $candidate.downloadBytes -or (Get-FileHash -LiteralPath $archive).Hash -ne $candidate.sha256){throw 'Candidate archive changed.'}
$review=Resolve-RepositoryFile $root $spec.publication.reviewEvidence.file
if((Get-FileHash -LiteralPath $review).Hash -ne $spec.publication.reviewEvidence.sha256){throw 'Material review record changed.'}
$sources=@()
foreach($item in $spec.publication.sourceAssets){
    $path=Resolve-RepositoryFile $SourceMaterialsDirectory $item.file
    if((Get-Item -LiteralPath $path).Length -ne $item.bytes -or (Get-FileHash -LiteralPath $path).Hash -ne $item.sha256){throw 'Corresponding source differs from reviewed materials.'}
    $sources+=$path
}
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $output){throw 'Use a new release preparation directory.'}
[IO.Directory]::CreateDirectory($output)|Out-Null
foreach($path in @($archive)+$sources){Copy-Item -LiteralPath $path -Destination $output}
Copy-Item -LiteralPath $ValidationFile -Destination (Join-Path $output 'validation.json')
Copy-Item -LiteralPath $review -Destination (Join-Path $output 'redistribution-review.json')
# 准备不是发布；只有核对真实公开 Release 的资产之后，记录才可转为 published。
$release.published=$false
$release|ConvertTo-Json -Depth 12|Set-Content -LiteralPath (Join-Path $output 'release-record.json') -Encoding utf8
@("# $($spec.displayName) $($spec.version)","",$spec.releaseNotes,"",'该版本通过离线构建及组件导入验证；不代表所有器件或硬件通过验收。',"",'对应源码及再分发审阅材料与二进制放在同一 Release，见 sourceAssets 和 redistribution-review.json。')|
    Set-Content -LiteralPath (Join-Path $output 'release-notes.md') -Encoding utf8
Get-ChildItem -LiteralPath $output -File|Sort-Object Name|ForEach-Object{(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant()+'  '+$_.Name}|
    Set-Content -LiteralPath (Join-Path $output 'SHA256SUMS.txt') -Encoding ascii
Write-Output $output
