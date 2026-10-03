param([Parameter(Mandatory)][string]$EncryptedKeyFile,[Parameter(Mandatory)][string]$PublicKeyFile)
$ErrorActionPreference='Stop'
if(!(($PSVersionTable.PSEdition -eq 'Core') -and $IsWindows)){throw 'Use PowerShell 7 on Windows; private keys use current-user DPAPI.'}
$root=Split-Path -Parent $PSScriptRoot
$private=[IO.Path]::GetFullPath($EncryptedKeyFile);$public=[IO.Path]::GetFullPath($PublicKeyFile)
if($private.StartsWith([IO.Path]::GetFullPath($root)+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Private keys must remain outside the repository.'}
if((Test-Path -LiteralPath $private) -or (Test-Path -LiteralPath $public)){throw 'Existing keys cannot be replaced.'}
$rsa=[Security.Cryptography.RSA]::Create(3072)
try{
    $bytes=$rsa.ExportPkcs8PrivateKey()
    try{$protected=[Security.Cryptography.ProtectedData]::Protect($bytes,$null,[Security.Cryptography.DataProtectionScope]::CurrentUser)}
    finally{[Security.Cryptography.CryptographicOperations]::ZeroMemory($bytes)}
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($private))|Out-Null
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($public))|Out-Null
    [IO.File]::WriteAllBytes($private,$protected)
    [IO.File]::WriteAllText($public,$rsa.ExportSubjectPublicKeyInfoPem()+"`n",[Text.UTF8Encoding]::new($false))
    @{formatVersion=1;algorithm='RSA-PSS-SHA256';keyBits=3072;publicKeyFile=[IO.Path]::GetFileName($public);
        spkiSha256=([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($rsa.ExportSubjectPublicKeyInfo()))).ToLowerInvariant()}|
        ConvertTo-Json|Set-Content -LiteralPath ([IO.Path]::ChangeExtension($public,'.json')) -Encoding utf8
}finally{$rsa.Dispose()}
