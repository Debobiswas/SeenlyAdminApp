# Generate a secure random password and create the keystore
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 18
$rng.GetBytes($bytes)
$password = [Convert]::ToBase64String($bytes)

# Save password to key.properties
$keystorePath = "$PSScriptRoot\app\seenly-release.keystore"
$keyPropertiesPath = "$PSScriptRoot\key.properties"

$keyProps = @"
storePassword=$password
keyPassword=$password
keyAlias=seenly-release
storeFile=seenly-release.keystore
"@

Set-Content -Path $keyPropertiesPath -Value $keyProps -Encoding UTF8

# Generate the keystore using keytool
$keytoolArgs = @(
    "-genkeypair",
    "-v",
    "-keystore", $keystorePath,
    "-alias", "seenly-release",
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", "10000",
    "-dname", "CN=Seenly Admin, OU=Mobile, O=Seenly, L=Unknown, ST=Unknown, C=US",
    "-storepass", $password,
    "-keypass", $password
)

& keytool @keytoolArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Keystore created at $keystorePath"
    Write-Host "key.properties saved at $keyPropertiesPath"
    Write-Host "Password saved to key.properties - KEEP THIS FILE SAFE and do NOT commit to git!"
} else {
    Write-Host "ERROR: keytool failed with exit code $LASTEXITCODE"
    exit 1
}
