; Inno Setup Script for Shellit Windows Installer
; Generates: Shellit-Setup-x64-v{#MyAppVersion}.exe

#define MyAppName "Shellit"
#ifndef MyAppVersion
  #define MyAppVersion "0.6.2"
#endif
#define MyAppPublisher "Kobalt"
#define MyAppURL "https://github.com/kobaltgit/Shellit"
#define MyAppExeName "shellit.exe"
#define BuildDir "..\..\apps\shellit\build\windows\x64\runner\Release"
#define IconFile "..\..\apps\shellit\windows\runner\resources\app_icon.ico"

[Setup]
AppId={{C8E303D8-76D4-4903-8F4C-675EFBB49210}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=Shellit-Setup-x64-v{#MyAppVersion}
OutputDir=..\..\build_output
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile={#IconFile}
UninstallDisplayIcon={app}\{#MyAppExeName}
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
