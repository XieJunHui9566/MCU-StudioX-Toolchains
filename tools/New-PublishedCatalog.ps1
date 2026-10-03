param([Parameter(Mandatory)][string]$EncryptedKeyFile,[Parameter(Mandatory)][string]$OutputDirectory,
    [string]$Repository='XieJunHui9566/MCU-StudioX-Toolchains',[switch]$AllowEmptyBootstrap)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Repository-Common.ps1')
$root=Split-Path -Parent $PSScriptRoot
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $output){throw 'Use a new catalog output directory.'}
if($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'){throw 'Invalid repository identity.'}
$index=Get-Content -LiteralPath (Join-Path $root 'releases/index.json') -Raw|ConvertFrom-Json
if($index.formatVersion -ne 1 -or $null -eq $index.releases -or $index.releases.Count -gt 1000){throw 'Invalid release index.'}
$entries=@();$identities=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($record in $index.releases){
    $release=Get-Content -LiteralPath (Resolve-RepositoryFile $root $record.record) -Raw|ConvertFrom-Json
    $spec=Read-ComponentSpec (Resolve-RepositoryFile (Join-Path $root 'components') ($release.id+'/'+$release.version+'/component.json'))
    if(!$identities.Add($spec.id+'/'+$spec.version)){throw 'Duplicate release identity.'}
    $entries+=Get-PublishedCatalogEntry $spec $release $Repository
    $review=Resolve-RepositoryFile $root $spec.publication.reviewEvidence.file
    if((Get-FileHash -LiteralPath $review).Hash -ne $spec.publication.reviewEvidence.sha256){throw 'Redistribution review record changed.'}
    # 非空正式目录核对 GitHub 已公开资产的摘要；不能把本地候选或草稿下载地址写成可用组件。
    $remoteText=& gh api ('repos/'+$Repository+'/releases/tags/'+$release.tag)
    if($LASTEXITCODE -ne 0){throw 'Published component release cannot be verified.'}
    $remote=$remoteText|ConvertFrom-Json
    if($remote.draft -or $remote.tag_name -cne $release.tag){throw 'Component release is unpublished or has a different tag.'}
    $required=@(@{file=$release.asset;sha256=$release.sha256;bytes=$release.downloadBytes})+@($release.sourceAssets)
    foreach($asset in $required){
        $found=@($remote.assets|Where-Object {$_.name -ceq $asset.file})
        if($found.Count -ne 1 -or $found[0].size -ne $asset.bytes -or $found[0].digest -ne ('sha256:'+$asset.sha256.ToLowerInvariant())){throw 'Published release assets differ from the approved exact bytes.'}
    }
}
if(!$entries.Count -and !$AllowEmptyBootstrap){throw 'No approved published components; empty bootstrap must be explicit.'}
$rsa=Get-PublisherRsa $EncryptedKeyFile
try{
    $public=Join-Path $root 'trust/publisher.pem'
    $trusted=[Security.Cryptography.RSA]::Create()
    try{$trusted.ImportFromPem([IO.File]::ReadAllText($public));if(![Convert]::ToHexString($trusted.ExportSubjectPublicKeyInfo()).Equals([Convert]::ToHexString($rsa.ExportSubjectPublicKeyInfo()),[StringComparison]::Ordinal)){throw 'Signing key does not match the committed publisher public key.'}}
    finally{$trusted.Dispose()}
    [IO.Directory]::CreateDirectory($output)|Out-Null
    $catalog=Join-Path $output 'catalog.json'
    $json=[ordered]@{formatVersion=1;publisher=$Repository;entries=$entries}|ConvertTo-Json -Depth 12
    [IO.File]::WriteAllText($catalog,$json.Replace("`r`n","`n")+"`n",[Text.UTF8Encoding]::new($false))
    $bytes=[IO.File]::ReadAllBytes($catalog)
    [IO.File]::WriteAllText($catalog+'.sig',[Convert]::ToBase64String($rsa.SignData($bytes,[Security.Cryptography.HashAlgorithmName]::SHA256,[Security.Cryptography.RSASignaturePadding]::Pss))+"`n",[Text.Encoding]::ASCII)
    Copy-Item -LiteralPath $public -Destination ($catalog+'.pub.pem')
}finally{$rsa.Dispose()}
Write-Output $catalog
