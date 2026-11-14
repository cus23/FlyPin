$ErrorActionPreference = "Stop"

$uri = "https://github.com/jkcoxson/idevice_pair/releases/download/0.1.14/idevice_pair--windows-x86_64.exe"
$expectedSha256 = "1969cc9e6ab8f749b3e1f810f02c5dccd000ce58d7b24fa79ddbb41942161436"
$destination = Join-Path $PSScriptRoot "idevice_pair--windows-x86_64.exe"

Write-Host "Downloading idevice_pair 0.1.14 for Windows (RPPairing-compatible fallback)..."
Invoke-WebRequest -Uri $uri -OutFile $destination

$actualSha256 = (Get-FileHash -Path $destination -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualSha256 -ne $expectedSha256) {
    Remove-Item -LiteralPath $destination -Force
    throw "SHA-256 verification failed. The downloaded executable was removed."
}

Write-Host "SHA-256 verified."
Write-Host "Connect and unlock your iPhone over USB, tap Trust, then create an RPPairing record."
Start-Process -FilePath $destination
