$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Path tools -Force | Out-Null

$nuspec = @'
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>daily-you</id>
    <version>3.4.7</version>
    <title>Daily You</title>
    <authors>BigWebstas</authors>
    <copyright>Copyright (c) 2026 BigWebstas</copyright>
    <projectUrl>https://github.com/BigWebstas/Daily_You</projectUrl>
    <licenseUrl>https://github.com/BigWebstas/Daily_You/blob/master/LICENSE.txt</licenseUrl>
    <requireLicenseAcceptance>true</requireLicenseAcceptance>
    <projectSourceUrl>https://github.com/BigWebstas/Daily_You</projectSourceUrl>
    <docsUrl>https://github.com/BigWebstas/Daily_You#readme</docsUrl>
    <bugTrackerUrl>https://github.com/BigWebstas/Daily_You/issues</bugTrackerUrl>
    <tags>daily-you journal journaling mood-tracker diary</tags>
    <summary>Every day is worth remembering...</summary>
    <description>
      A journaling app for tracking your mood, daily logs, photo memories,
      and Markdown notes.
    </description>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
'@
Set-Content -Path daily-you.nuspec -Value $nuspec

$installScript = @'
$ErrorActionPreference = 'Stop'
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url64bit       = 'https://github.com/BigWebstas/Daily_You/releases/download/v3.4.7/DailyYou-3.4.7-windows-x64-setup.exe'
  softwareName   = 'Daily You*'
  checksum64     = '870c4aebe966b463a9080b16b1931417dfb82dc91c252d90c45f50be43cf133d'
  checksumType64 = 'sha256'
  silentArgs     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
  validExitCodes = @(0)
}
Install-ChocolateyPackage @packageArgs
'@
Set-Content -Path tools\chocolateyinstall.ps1 -Value $installScript

$uninstallScript = @'
$ErrorActionPreference = 'Stop'
$softwareName = 'Daily You*'
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  silentArgs     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'
  validExitCodes = @(0)
}
[array]$key = Get-UninstallRegistryKey -SoftwareName $softwareName
if ($key.Count -eq 1) {
  $key | ForEach-Object {
    $packageArgs['file'] = "$($_.UninstallString)".Trim('"')
    Uninstall-ChocolateyPackage @packageArgs
  }
} elseif ($key.Count -eq 0) {
  Write-Warning "$($packageArgs.packageName) has already been uninstalled by other means."
}
'@
Set-Content -Path tools\chocolateyuninstall.ps1 -Value $uninstallScript

choco pack daily-you.nuspec

Write-Host ""
Write-Host "Package built. Push it with:"
Write-Host "  choco push .\daily-you.3.4.7.nupkg --source https://push.chocolatey.org/ --api-key <YOUR_API_KEY>"
