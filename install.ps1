# FREGONATOR Quick Installer v6.0
# Usage: irm fregonator.com/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$version = '6.0'
$downloadUrl = 'https://github.com/dthcst/fregonator/releases/download/v6.0/FREGONATOR-6.0-Setup.zip'
$installPath = "$env:LOCALAPPDATA\FREGONATOR"

Write-Host ''
Write-Host '  FREGONATOR Quick Installer v6.0' -ForegroundColor Cyan
Write-Host '  https://fregonator.com' -ForegroundColor Gray
Write-Host ''

try {
    Write-Host '  [1/3] Downloading...' -ForegroundColor Yellow
    $tempZip = "$env:TEMP\fregonator-install.zip"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
    Write-Host '        OK' -ForegroundColor Green

    Write-Host '  [2/3] Installing...' -ForegroundColor Yellow
    if (Test-Path $installPath) { Remove-Item $installPath -Recurse -Force }
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    Expand-Archive -Path $tempZip -DestinationPath $installPath -Force
    Write-Host '        OK' -ForegroundColor Green

    Write-Host '  [3/3] Creating shortcut...' -ForegroundColor Yellow
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\FREGONATOR.lnk")
    $shortcut.TargetPath = "$installPath\FREGONATOR.bat"
    $shortcut.WorkingDirectory = $installPath
    $shortcut.IconLocation = "$installPath\fregonator.ico"
    $shortcut.Save()
    Write-Host '        OK' -ForegroundColor Green

    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue

    Write-Host ''
    Write-Host '  FREGONATOR installed!' -ForegroundColor Green
    Write-Host "  Location: $installPath" -ForegroundColor Gray
    Write-Host ''
    Write-Host '  Launching...' -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    Start-Process "$installPath\FREGONATOR.bat" -WorkingDirectory $installPath

} catch {
    Write-Host ''
    Write-Host "  [ERROR] $_" -ForegroundColor Red
    Write-Host '  Download manually: https://fregonator.com' -ForegroundColor Yellow
}
