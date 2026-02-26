param(
  [string]$Version = "2.0.0",
  [string]$FlutterPath = "C:\Users\Jose\flutter\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path
$projectDir = Join-Path $repoRoot "rbp_flutter"
$distDir = Join-Path $repoRoot "dist"
$releaseDir = Join-Path $projectDir "build\windows\x64\runner\Release"
$sourceExe = Join-Path $releaseDir "rbp_flutter.exe"
$bundleDir = Join-Path $distDir "RBP_Keygen_Tool_$Version"
$targetExe = Join-Path $bundleDir "RBP_Keygen_Tool_$Version.exe"
$zipPath = Join-Path $distDir "RBP_Keygen_Tool_$Version.zip"

if (-not (Test-Path $FlutterPath)) {
  throw "No se encontro flutter.bat en: $FlutterPath"
}

Write-Host "Compilando herramienta grafica de keygen..."
Push-Location $projectDir
try {
  & $FlutterPath build windows --release --target lib/main_keygen.dart --no-pub
  if ($LASTEXITCODE -ne 0) {
    throw "Fallo el build de keygen tool."
  }
} finally {
  Pop-Location
}

if (-not (Test-Path $sourceExe)) {
  throw "No se encontro ejecutable compilado: $sourceExe"
}

New-Item -ItemType Directory -Force -Path $distDir | Out-Null
if (Test-Path $bundleDir) {
  Remove-Item -Recurse -Force $bundleDir
}
Copy-Item -Recurse -Force $releaseDir $bundleDir

if (Test-Path $targetExe) {
  Remove-Item -Force $targetExe
}
Rename-Item -Path (Join-Path $bundleDir "rbp_flutter.exe") -NewName "RBP_Keygen_Tool_$Version.exe"

if (Test-Path $zipPath) {
  Remove-Item -Force $zipPath
}
Compress-Archive -Path "$bundleDir\*" -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host "OK -> $targetExe"
Write-Host "OK -> $zipPath"
