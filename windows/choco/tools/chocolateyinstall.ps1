$ErrorActionPreference = 'Stop'

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url64bit       = 'https://github.com/BigWebstas/Daily_You/releases/download/v3.4.3/DailyYou-3.4.3-windows-x64-setup.exe'
  softwareName   = 'Daily You*'
  checksum64     = 'ef78d49fbed05e945838a0e1eeb8c24edd6be627be8ee249f73f9551e32d37a8'
  checksumType64 = 'sha256'
  silentArgs     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
