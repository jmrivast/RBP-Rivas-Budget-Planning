$ErrorActionPreference = 'Stop'

Set-Location (Split-Path -Parent $PSScriptRoot)

if (Test-Path .\dist\RBP_onedir) {
    Remove-Item .\dist\RBP_onedir -Recurse -Force
}

python -m PyInstaller --noconfirm --clean --noupx --onedir --windowed --name RBP_onedir --icon=icon.ico --add-data "Untitled.png;." --add-data "icon.ico;." main.py

if (Test-Path .\dist\RBP_onedir.zip) {
    Remove-Item .\dist\RBP_onedir.zip -Force
}

Compress-Archive -Path .\dist\RBP_onedir\* -DestinationPath .\dist\RBP_onedir.zip -Force
Write-Output "Build listo: dist/RBP_onedir.zip"
