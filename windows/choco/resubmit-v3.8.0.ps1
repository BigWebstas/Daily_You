param(
  [string]$Version = '3.8.0'
)

$ErrorActionPreference = 'Stop'

# Mirrors the "Point package at this release" step in release.yml's build-choco
# job, but stages a copy so the checked-in nuspec/install script stay untouched.
$tag = "v$Version"
$installerName = "DailyYou-$Version-windows-x64-setup.exe"
$installerUrl = "https://github.com/BigWebstas/Daily_You/releases/download/$tag/$installerName"

$stage = Join-Path ([IO.Path]::GetTempPath()) "daily-you-choco-$Version"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item "$PSScriptRoot\daily-you.nuspec" $stage
Copy-Item "$PSScriptRoot\tools" $stage -Recurse

# Hash the published release asset, which is what the package downloads.
$installer = Join-Path $stage $installerName
Invoke-WebRequest -Uri $installerUrl -OutFile $installer
$sha256 = (Get-FileHash $installer -Algorithm SHA256).Hash.ToLower()
Remove-Item $installer

$nuspec = Join-Path $stage 'daily-you.nuspec'
(Get-Content $nuspec) -replace '<version>[\d.]+</version>', "<version>$Version</version>" | Set-Content $nuspec

$installScript = Join-Path $stage 'tools\chocolateyinstall.ps1'
(Get-Content $installScript) `
  -replace 'releases/download/v[\d.]+/DailyYou-[\d.]+-windows-x64-setup\.exe', "releases/download/$tag/$installerName" `
  -replace "checksum64\s*=\s*'.*'", "checksum64     = '$sha256'" |
  Set-Content $installScript

choco pack $nuspec --outputdirectory $stage

$nupkg = Join-Path $stage "daily-you.$Version.nupkg"
Write-Host ""
Write-Host "SHA256: $sha256"
Write-Host "Package built. Push it with:"
Write-Host "  choco push `"$nupkg`" --source https://push.chocolatey.org/ --api-key <YOUR_API_KEY>"
