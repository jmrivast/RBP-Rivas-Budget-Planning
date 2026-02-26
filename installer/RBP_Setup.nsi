; NSIS installer script for RBP - Rivas Budget Planning (Windows)
; Build app first:
;   flutter build windows --release
;
; Compile:
;   makensis installer\RBP_Setup.nsi
; Or:
;   powershell -ExecutionPolicy Bypass -File installer\build_nsis.ps1 -Version 2.0.0

Unicode true

!include "MUI2.nsh"
!include "x64.nsh"

!ifndef APP_NAME
!define APP_NAME "RBP"
!define APP_FULL_NAME "RBP - Rivas Budget Planning"
!endif
!ifndef APP_PUBLISHER
  !define APP_PUBLISHER "Rivas Budget Planning"
!endif
!ifndef APP_EXE_NAME
  !define APP_EXE_NAME "rbp_flutter.exe"
!endif
!ifndef APP_VERSION
  !define APP_VERSION "2.0.0"
!endif
!ifndef SOURCE_RELEASE
  !define SOURCE_RELEASE "..\rbp_flutter\build\windows\x64\runner\Release"
!endif
!ifndef OUTPUT_DIR
  !define OUTPUT_DIR "..\dist"
!endif

Name "${APP_NAME}"
OutFile "${OUTPUT_DIR}\RBP_Setup_${APP_VERSION}.exe"
InstallDir "$LOCALAPPDATA\Programs\RBP"
InstallDirRegKey HKCU "Software\RivasBudgetPlanning\RBP" "InstallDir"
RequestExecutionLevel user

SetCompressor /SOLID lzma
SetCompressorDictSize 32

!define MUI_ABORTWARNING
!define MUI_ICON "..\icon.ico"
!define MUI_UNICON "..\icon.ico"
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE_NAME}"
!define MUI_FINISHPAGE_RUN_TEXT "Abrir RBP ahora"

VIProductVersion "2.0.0.0"
VIAddVersionKey "ProductName" "${APP_FULL_NAME}"
VIAddVersionKey "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription" "${APP_NAME} Setup"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "Copyright (c) Rivas Budget Planning"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "English"

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "Esta version requiere Windows 64-bit."
    Abort
  ${EndIf}
FunctionEnd

Section "RBP Core" SecCore
  SetOutPath "$INSTDIR"
  File /r "${SOURCE_RELEASE}\*"

  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\RivasBudgetPlanning\RBP" "InstallDir" "$INSTDIR"

  CreateDirectory "$SMPROGRAMS\RBP"
  CreateShortcut "$SMPROGRAMS\RBP\${APP_FULL_NAME}.lnk" "$INSTDIR\${APP_EXE_NAME}" "" "$INSTDIR\${APP_EXE_NAME}" 0
  CreateShortcut "$SMPROGRAMS\RBP\Desinstalar RBP.lnk" "$INSTDIR\Uninstall.exe"
  CreateShortcut "$DESKTOP\${APP_FULL_NAME}.lnk" "$INSTDIR\${APP_EXE_NAME}" "" "$INSTDIR\${APP_EXE_NAME}" 0

  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBP" "DisplayName" "${APP_FULL_NAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBP" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBP" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBP" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBP" "DisplayIcon" "$INSTDIR\${APP_EXE_NAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBP" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBP" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBP" "NoRepair" 1
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\${APP_FULL_NAME}.lnk"
  Delete "$SMPROGRAMS\RBP\${APP_FULL_NAME}.lnk"
  Delete "$SMPROGRAMS\RBP\Desinstalar RBP.lnk"
  RMDir "$SMPROGRAMS\RBP"

  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR"

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBP"
  DeleteRegKey HKCU "Software\RivasBudgetPlanning\RBP"
SectionEnd
