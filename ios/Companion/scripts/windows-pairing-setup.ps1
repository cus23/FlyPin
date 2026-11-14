$ErrorActionPreference = "Stop"

$uri = "https://github.com/jkcoxson/idevice_pair/releases/download/v1.1.0/idevice_pair--windows-x86_64.exe"
$expectedSha256 = "a47bc9ef999d086b402fb2c9b3bd9cbed6fceb8718ad36b098b5ed32abbbe53b"
$destination = Join-Path $PSScriptRoot "idevice_pair--windows-x86_64.exe"

Write-Host "Downloading idevice_pair 1.1.0 for Windows..."
Invoke-WebRequest -Uri $uri -OutFile $destination

$actualSha256 = (Get-FileHash -Path $destination -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualSha256 -ne $expectedSha256) {
    Remove-Item -LiteralPath $destination -Force
    throw "SHA-256 verification failed. The downloaded executable was removed."
}

Write-Host "SHA-256 verified."
Write-Host "Connect and unlock your iPhone over USB, tap Trust, then create an RPPairing record."
Start-Process -FilePath $destination
