function Assert-ComponentIdentity($Spec) {
    if($Spec.formatVersion -ne 1 -or $Spec.id -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$' -or
        $Spec.version -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -or $Spec.host -ne 'win-x64' -or
        [string]::IsNullOrWhiteSpace($Spec.compilerId) -or $Spec.manifestSha256 -notmatch '^[0-9a-fA-F]{64}$') {throw 'Invalid exact component identity.'}
}
function Assert-PublicUrl([string]$Value) {
    $uri=$null
    if(![Uri]::TryCreate($Value,[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -ne 'https' -or $uri.UserInfo -or $uri.Fragment) {throw 'Expected a public HTTPS URL without credentials or fragment.'}
}
function Resolve-RepositoryFile([string]$Root,[string]$Relative) {
    if(!$Relative -or $Relative -match '(^|[\\/])\.\.([\\/]|$)|:|^[\\/]'){throw 'Expected a relative repository file.'}
    $rootPath=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($Root))
    $path=[IO.Path]::GetFullPath((Join-Path $rootPath $Relative))
    if(!$path.StartsWith($rootPath+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Path leaves repository boundary.'}
    $item=Get-Item -LiteralPath $path -Force
    while($item){if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked repository files are not accepted.'};$item=if($item.PSIsContainer){$item.Parent}else{$item.Directory}}
    return $path
}
function Read-ComponentSpec([string]$Path) {
    $spec=Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json
    Assert-ComponentIdentity $spec
    if(!$spec.sourceUrls.Count -or !$spec.displayName -or !$spec.releaseNotes){throw 'Component source and description are required.'}
    foreach($url in $spec.sourceUrls){Assert-PublicUrl $url}
    if($spec.publication.status -notin @('pending-materials','ready')){throw 'Unknown publication status.'}
    return $spec
}
function Get-PublishedCatalogEntry($Spec,$Release,[string]$Repository) {
    Assert-ComponentIdentity $Spec
    # 发布条件来自已审阅的材料和验证记录；签名只证明发布者认可该记录，不代替许可证审阅。
    if($Spec.publication.status -ne 'ready' -or $Spec.publication.blockers.Count -or $Spec.license -eq 'NOASSERTION' -or !$Spec.license -or
        $Spec.publication.sourceAssets.Count -eq 0 -or $Spec.publication.reviewEvidence.sha256 -notmatch '^[0-9a-fA-F]{64}$'){throw 'Component is not approved for public redistribution.'}
    if($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'){throw 'Invalid repository identity.'}
    $tag=$Spec.id+'-'+$Spec.version+'-'+$Spec.host
    $asset=$tag+'.mcutoolchain'
    if($Release.formatVersion -ne 1 -or $Release.id -cne $Spec.id -or $Release.version -ne $Spec.version -or $Release.host -ne $Spec.host -or
        $Release.compilerId -cne $Spec.compilerId -or $Release.manifestSha256 -ne $Spec.manifestSha256 -or $Release.tag -cne $tag -or
        $Release.asset -cne $asset -or $Release.sha256 -notmatch '^[0-9a-fA-F]{64}$' -or $Release.downloadBytes -lt 1 -or
        $Release.downloadBytes -ge 2GB -or $Release.installedBytes -lt 1 -or $Release.installedBytes -gt 32GB -or $Release.published -ne $true){throw 'Release identity, status or GitHub asset size is invalid.'}
    if($Release.validation.status -ne 'passed' -or $Release.validation.scope -ne 'offline-build-and-import' -or
        $Release.validation.archiveSha256 -ne $Release.sha256 -or $Release.validation.manifestSha256 -ne $Spec.manifestSha256 -or
        $Release.validation.evidenceSha256 -notmatch '^[0-9a-fA-F]{64}$' -or $Release.reviewEvidenceSha256 -ne $Spec.publication.reviewEvidence.sha256){throw 'Release validation or material review does not bind the exact component bytes.'}
    $download='https://github.com/'+$Repository+'/releases/download/'+$tag+'/'
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($source in $Spec.publication.sourceAssets){
        if($source.file -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,180}$' -or !$seen.Add($source.file) -or
            $source.sha256 -notmatch '^[0-9a-fA-F]{64}$' -or $source.bytes -lt 1 -or $source.bytes -ge 2GB){throw 'Invalid corresponding-source release asset.'}
        $delivered=@($Release.sourceAssets|Where-Object {$_.file -ceq $source.file -and $_.sha256 -eq $source.sha256 -and $_.bytes -eq $source.bytes -and $_.url -ceq ($download+$source.file)})
        if($delivered.Count -ne 1){throw 'Corresponding source is not delivered by the pinned release.'}
    }
    return [ordered]@{kind='tool';id=$Spec.id;version=$Spec.version;name=$Spec.displayName;archive=($download+$asset);
        sha256=$Release.sha256;downloadBytes=[long]$Release.downloadBytes;installedBytes=[long]$Release.installedBytes;
        license=$Spec.license;sourceUrl=('https://github.com/'+$Repository+'/tree/main/components/'+$Spec.id+'/'+$Spec.version);
        releaseNotes=$Spec.releaseNotes;pluginApi=0;frameworks=@()}
}
function Get-PublisherRsa([string]$EncryptedKeyFile) {
    $rsa=[Security.Cryptography.RSA]::Create()
    $bytes=[Security.Cryptography.ProtectedData]::Unprotect([IO.File]::ReadAllBytes([IO.Path]::GetFullPath($EncryptedKeyFile)),
        $null,[Security.Cryptography.DataProtectionScope]::CurrentUser)
    try{$read=0;$rsa.ImportPkcs8PrivateKey($bytes,[ref]$read);if($read -ne $bytes.Length -or $rsa.KeySize -lt 3072){throw 'Invalid publisher key.'}}
    catch{$rsa.Dispose();throw}
    finally{[Security.Cryptography.CryptographicOperations]::ZeroMemory($bytes)}
    return $rsa
}
