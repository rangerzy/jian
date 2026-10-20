#ifndef AppVersion
  #error AppVersion must be supplied by the packaging script.
#endif
#ifndef StageDir
  #error StageDir must be supplied by the packaging script.
#endif
#ifndef DistDir
  #error DistDir must be supplied by the packaging script.
#endif

[Setup]
AppId=io.github.rangerzy.jian
AppName=jian
AppVersion={#AppVersion}
AppPublisher=rangerzy
AppPublisherURL=https://github.com/rangerzy/jian
AppSupportURL=https://github.com/rangerzy/jian/issues
DefaultDirName={localappdata}\Programs\jian
DefaultGroupName=jian
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#DistDir}
OutputBaseFilename=jian-{#AppVersion}-windows-x64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\jian.exe
VersionInfoVersion={#AppVersion}

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\jian"; Filename: "{app}\jian.exe"

[Run]
Filename: "{app}\jian.exe"; Description: "Launch jian"; Flags: nowait postinstall skipifsilent
