param([Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Repository-Common.ps1')
$root=Split-Path -Parent $PSScriptRoot
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $output){throw 'Use a new validation directory.'}
if($output.StartsWith([IO.Path]::GetFullPath($root)+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Keep test fixtures outside repository.'}
[IO.Directory]::CreateDirectory($output)|Out-Null
$checks=[Collections.Generic.List[string]]::new()
function Check([bool]$Passed,[string]$Name){if(!$Passed){throw $Name};$checks.Add($Name);Write-Output "PASS $Name"}
function Reject([scriptblock]$Action,[string]$Name){$failed=$false;try{& $Action|Out-Null}catch{$failed=$true};Check $failed $Name}
$index=Get-Content -LiteralPath (Join-Path $root 'components/index.json') -Raw|ConvertFrom-Json
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($entry in $index.components){
    $spec=Read-ComponentSpec (Resolve-RepositoryFile (Join-Path $root 'components') $entry.specification)
    Check ($seen.Add($spec.id+'/'+$spec.version) -and $spec.id -ceq $entry.id -and $spec.version -eq $entry.version -and $spec.host -eq $entry.host -and $spec.publication.status -eq $entry.publicationStatus) "registry retains unique exact identity $($spec.id) $($spec.version)"
}
$rsa=[Security.Cryptography.RSA]::Create()
try{
    $rsa.ImportFromPem([IO.File]::ReadAllText((Join-Path $root 'trust/publisher.pem')))
    $bytes=[IO.File]::ReadAllBytes((Join-Path $root 'catalog/catalog.json'))
    $signature=[Convert]::FromBase64String([IO.File]::ReadAllText((Join-Path $root 'catalog/catalog.json.sig')).Trim())
    $trust=Get-Content -LiteralPath (Join-Path $root 'trust/publisher.json') -Raw|ConvertFrom-Json
    Check ($rsa.KeySize -eq 3072 -and ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($rsa.ExportSubjectPublicKeyInfo()))) -eq $trust.spkiSha256) 'committed public key matches the declared SPKI fingerprint'
    Check ($rsa.VerifyData($bytes,$signature,[Security.Cryptography.HashAlgorithmName]::SHA256,[Security.Cryptography.RSASignaturePadding]::Pss)) 'committed catalog has a valid RSA-PSS/SHA-256 signature'
    $changed=[byte[]]$bytes.Clone();$changed[0]=$changed[0] -bxor 1
    Check (!$rsa.VerifyData($changed,$signature,[Security.Cryptography.HashAlgorithmName]::SHA256,[Security.Cryptography.RSASignaturePadding]::Pss)) 'one changed catalog byte invalidates the signature'
}finally{$rsa.Dispose()}
$catalog=Get-Content -LiteralPath (Join-Path $root 'catalog/catalog.json') -Raw|ConvertFrom-Json
$releases=Get-Content -LiteralPath (Join-Path $root 'releases/index.json') -Raw|ConvertFrom-Json
Check ($catalog.formatVersion -eq 1 -and $catalog.entries.Count -eq $releases.releases.Count) 'signed directory count matches the published Release registry'
$releaseSeen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($reference in $releases.releases){
    $release=Get-Content -LiteralPath (Resolve-RepositoryFile $root $reference.record) -Raw|ConvertFrom-Json
    $spec=Read-ComponentSpec (Resolve-RepositoryFile $root ('components/'+$release.id+'/'+$release.version+'/component.json'))
    $expected=Get-PublishedCatalogEntry $spec $release 'XieJunHui9566/MCU-StudioX-Toolchains'
    $actual=@($catalog.entries|Where-Object {$_.kind -ceq 'tool' -and $_.id -ceq $spec.id -and $_.version -ceq $spec.version})
    Check ($releaseSeen.Add($spec.id+'/'+$spec.version) -and $actual.Count -eq 1) 'each published component has one signed directory entry'
    foreach($property in $expected.Keys){
        if(($expected[$property]|ConvertTo-Json -Depth 8 -Compress) -cne ($actual[0].$property|ConvertTo-Json -Depth 8 -Compress)){throw "Signed catalog differs from reviewed Release: $property"}
    }
    $reviewPath=Resolve-RepositoryFile $root $spec.publication.reviewEvidence.file
    Check ((Get-FileHash -LiteralPath $reviewPath).Hash -eq $spec.publication.reviewEvidence.sha256) 'published review bytes match the component and Release fingerprints'
}
foreach($file in Get-ChildItem -LiteralPath $root -File -Recurse -Force|Where-Object {$_.FullName -notlike ($root+'\.git\*')}){
    if($file.Extension -in @('.exe','.dll','.zip','.mcutoolchain','.studioxtools','.dpapi','.pfx','.key')){throw 'Binary or private-key file entered the public repository.'}
    $text=[IO.File]::ReadAllText($file.FullName)
    if($text -match '-----BEGIN (?:RSA )?PRIVATE KEY-----' -or $text -match '(?i)[A-Z]:[\\/]Users[\\/]'){throw 'Secret material or developer account path entered the public repository.'}
}
$checks.Add('repository contains no binary payload, private signing key or developer account path')
foreach($script in Get-ChildItem -LiteralPath $root -Filter '*.ps1' -Recurse){$tokens=$null;$errors=$null;[Management.Automation.Language.Parser]::ParseFile($script.FullName,[ref]$tokens,[ref]$errors)|Out-Null;if($errors.Count){throw "PowerShell parse errors: $($script.Name)"}}
$checks.Add('all publication and packaging scripts parse')
$spec=Read-ComponentSpec (Join-Path $root 'components/stc.sdcc/1.0.0/component.json')
$spec.id='test.component';$spec.compilerId='test-compiler';$spec.license='MIT';$spec.publication.status='ready';$spec.publication.blockers=@()
$spec.publication.sourceAssets=@(@{file='test-source.zip';sha256=('b'*64);bytes=10})
$spec.publication.reviewEvidence=@{file='reviews/test.json';sha256=('c'*64)}
$release=[pscustomobject]@{formatVersion=1;id=$spec.id;version=$spec.version;host=$spec.host;compilerId=$spec.compilerId;manifestSha256=$spec.manifestSha256;
    tag='test.component-1.0.0-win-x64';asset='test.component-1.0.0-win-x64.mcutoolchain';sha256=('a'*64);downloadBytes=20;installedBytes=40;published=$true;
    validation=@{status='passed';scope='offline-build-and-import';manifestSha256=$spec.manifestSha256;archiveSha256=('a'*64);evidenceSha256=('d'*64)};
    reviewEvidenceSha256=('c'*64);sourceAssets=@(@{file='test-source.zip';sha256=('b'*64);bytes=10;url='https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/download/test.component-1.0.0-win-x64/test-source.zip'})}
$repository='XieJunHui9566/MCU-StudioX-Toolchains'
$entry=Get-PublishedCatalogEntry $spec $release $repository
Check ($entry.archive -ceq ('https://github.com/'+$repository+'/releases/download/test.component-1.0.0-win-x64/test.component-1.0.0-win-x64.mcutoolchain')) 'approved metadata maps to a stable per-component Release URL'
function Clone($Value){return $Value|ConvertTo-Json -Depth 15|ConvertFrom-Json}
$bad=Clone $spec;$bad.publication.status='pending-materials';Reject {Get-PublishedCatalogEntry $bad $release $repository} 'pending redistribution materials stop before catalog or network publication'
$bad=Clone $spec;$bad.license='NOASSERTION';Reject {Get-PublishedCatalogEntry $bad $release $repository} 'unreviewed license cannot enter a published directory'
$bad=Clone $spec;$bad.version='latest';Reject {Get-PublishedCatalogEntry $bad $release $repository} 'floating versions cannot enter a published directory'
$bad=Clone $release;$bad.manifestSha256=('e'*64);Reject {Get-PublishedCatalogEntry $spec $bad $repository} 'release cannot change an existing component manifest fingerprint'
$bad=Clone $release;$bad.compilerId='another-compiler';Reject {Get-PublishedCatalogEntry $spec $bad $repository} 'release compiler identity must match the reviewed component'
$bad=Clone $release;$bad.downloadBytes=2GB;Reject {Get-PublishedCatalogEntry $spec $bad $repository} 'GitHub single asset size boundary rejects files of 2 GiB or larger'
$bad=Clone $release;$bad.published=$false;Reject {Get-PublishedCatalogEntry $spec $bad $repository} 'local candidates and draft releases cannot become directory entries'
$bad=Clone $release;$bad.validation.archiveSha256=('f'*64);Reject {Get-PublishedCatalogEntry $spec $bad $repository} 'native validation must bind the exact downloadable archive'
$bad=Clone $release;$bad.validation.scope='identity-inventory';Reject {Get-PublishedCatalogEntry $spec $bad $repository} 'metadata inspection alone is insufficient for a public native toolchain'
$bad=Clone $release;$bad.sourceAssets=@();Reject {Get-PublishedCatalogEntry $spec $bad $repository} 'source URL lists cannot substitute for delivered corresponding-source assets'
$bad=Clone $spec;$bad.publication.sourceAssets[0].file='../source.zip';Reject {Get-PublishedCatalogEntry $bad $release $repository} 'source asset traversal is rejected'
Reject {Resolve-RepositoryFile $root '../outside.txt'} 'repository file references cannot escape the root'
Reject {Assert-PublicUrl 'http://example.com/source'} 'insecure source URLs are rejected'
Reject {Assert-PublicUrl 'https://account:password@example.com/source'} 'source URLs cannot contain account credentials'
@{success=$true;hardware=$false;network=$false;fixtureToolsExecuted=$false;componentRecords=$index.components.Count;checks=$checks}|
    ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $output 'result.json') -Encoding utf8
Write-Output "$($checks.Count) repository checks passed."
