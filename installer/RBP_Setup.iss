; Inno Setup script for RBP - Rivas Budget Planning (Flutter Windows Release)
; Build app first:
;   flutter build windows --release
;
; Then compile this .iss with Inno Setup Compiler.

#define MyAppName "RBP - Rivas Budget Planning"
#define MyAppPublisher "Rivas Budget Planning"
#define MyAppExeName "rbp_flutter.exe"
#define MyAppVersion "2.0.0"
#define SourceRelease "..\\rbp_flutter\\build\\windows\\x64\\runner\\Release"

[Setup]
AppId={{A1BA2D5D-73A0-4A83-A6A0-9A5B5BE8D6C9}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\RBP
DefaultGroupName=RBP
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=RBP_Setup_{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ShowLanguageDialog=no
PrivilegesRequired=lowest
SetupIconFile=..\icon.ico
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos:"; Flags: unchecked

[Files]
Source: "{#SourceRelease}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\RBP - Rivas Budget Planning"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\RBP - Rivas Budget Planning"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir RBP ahora"; Flags: nowait postinstall skipifsilent
