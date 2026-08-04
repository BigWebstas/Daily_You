; Inno Setup script for the Daily You Windows installer.
;
; Build the app first, then compile this script:
;   flutter build windows --release
;   ISCC.exe windows\installer\daily_you.iss
;
; Override the version at compile time to match pubspec.yaml:
;   ISCC.exe /DMyAppVersion=3.1.0 windows\installer\daily_you.iss

#define MyAppName "Daily You"
#ifndef MyAppVersion
  #define MyAppVersion "3.0.0"
#endif
#define MyAppPublisher "Demizo"
#define MyAppURL "https://github.com/Demizo/Daily_You"
#define MyAppExeName "daily_you.exe"

; Paths are relative to this script's directory (windows\installer).
#define ProjectRoot "..\.."
#define BuildDir ProjectRoot + "\build\windows\x64\runner\Release"

[Setup]
AppId={{8C6F2A31-4D5B-4E7C-9A18-2F3B6D0C5E44}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile={#ProjectRoot}\LICENSE.txt
OutputDir={#ProjectRoot}\build\windows\installer
OutputBaseFilename=DailyYou-{#MyAppVersion}-windows-x64-setup
SetupIconFile={#ProjectRoot}\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; The Flutter runner is 64-bit only.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Default to a machine-wide install, but let the user drop to a per-user
; install if they are not an administrator.
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\*"; DestDir: "{app}"; Excludes: "{#MyAppExeName}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
