param(
  [string]$Version = "2.0.0",
  [string]$MakensisPath = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path
$releaseDir = Join-Path $repoRoot "rbp_flutter\build\windows\x64\runner\Release"
$nsiScript = Join-Path $scriptDir "RBP_Setup.nsi"
$outputDir = Join-Path $repoRoot "dist"

if (-not (Test-Path $nsiScript)) {
  throw "No se encontro el script NSIS: $nsiScript"
}

if (-not (Test-Path (Join-Path $releaseDir "rbp_flutter.exe"))) {
  throw "No se encontro build release. Ejecuta: flutter build windows --release"
}

if (-not $MakensisPath) {
  $cmd = Get-Command makensis -ErrorAction SilentlyContinue
  if ($cmd) {
    $MakensisPath = $cmd.Source
  } else {
    $defaultNsis = "${env:ProgramFiles(x86)}\NSIS\makensis.exe"
    if (Test-Path $defaultNsis) {
      $MakensisPath = $defaultNsis
    } else {
      throw "No se encontro makensis.exe. Instala NSIS: winget install -e --id NSIS.NSIS"
    }
  }
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Write-Host "Compilando instalador NSIS..."
& $MakensisPath /V3 "/DAPP_VERSION=$Version" "/DSOURCE_RELEASE=$releaseDir" "/DOUTPUT_DIR=$outputDir" $nsiScript
if ($LASTEXITCODE -ne 0) {
  throw "Fallo la compilacion de NSIS (exit code $LASTEXITCODE)."
}

$installerPath = Join-Path $outputDir "RBP_Setup_$Version.exe"
if (-not (Test-Path $installerPath)) {
  throw "Compilacion finalizada pero no se encontro el instalador esperado: $installerPath"
}

Write-Host "Instalador generado: $installerPath"
