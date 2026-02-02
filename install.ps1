# FREGONATOR Quick Installer
# Usage: irm https://raw.githubusercontent.com/dthcst/fregonator/main/install.ps1 | iex

$repo = "dthcst/fregonator"
$installPath = "$env:LOCALAPPDATA\FREGONATOR"

Clear-Host

# Banner
Write-Host ""
Write-Host "  ███████╗██████╗ ███████╗ ██████╗  ██████╗ ███╗   ██╗ █████╗ ████████╗ ██████╗ ██████╗ " -ForegroundColor Cyan
Write-Host "  ██╔════╝██╔══██╗██╔════╝██╔════╝ ██╔═══██╗████╗  ██║██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗" -ForegroundColor Cyan
Write-Host "  █████╗  ██████╔╝█████╗  ██║  ███╗██║   ██║██╔██╗ ██║███████║   ██║   ██║   ██║██████╔╝" -ForegroundColor Cyan
Write-Host "  ██╔══╝  ██╔══██╗██╔══╝  ██║   ██║██║   ██║██║╚██╗██║██╔══██║   ██║   ██║   ██║██╔══██╗" -ForegroundColor Cyan
Write-Host "  ██║     ██║  ██║███████╗╚██████╔╝╚██████╔╝██║ ╚████║██║  ██║   ██║   ╚██████╔╝██║  ██║" -ForegroundColor Cyan
Write-Host "  ╚═╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Quick Installer" -ForegroundColor White
Write-Host ""

try {
    # Download
    Write-Host "  [1/4] Downloading FREGONATOR..." -ForegroundColor Yellow
    $downloadUrl = "https://github.com/$repo/archive/refs/heads/main.zip"
    $tempZip = "$env:TEMP\fregonator-install.zip"
    $tempDir = "$env:TEMP\fregonator-extract"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
    Write-Host "        OK" -ForegroundColor Green

    # Extract
    Write-Host "  [2/4] Extracting..." -ForegroundColor Yellow
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
    Write-Host "        OK" -ForegroundColor Green

    # Install
    Write-Host "  [3/4] Installing to $installPath..." -ForegroundColor Yellow
    $sourceDir = Get-ChildItem $tempDir -Directory | Select-Object -First 1
    if ($sourceDir) { $sourceDir = $sourceDir.FullName } else { $sourceDir = $tempDir }

    if (Test-Path $installPath) { Remove-Item $installPath -Recurse -Force }
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    Copy-Item "$sourceDir\*" -Destination $installPath -Recurse -Force
    Write-Host "        OK" -ForegroundColor Green

    # Shortcuts
    Write-Host "  [4/4] Creating shortcut..." -ForegroundColor Yellow

    $batPath = "$installPath\FREGONATOR.bat"
    $icoPath = "$installPath\fregonator.ico"

    if (Test-Path $batPath) {
        $WshShell = New-Object -ComObject WScript.Shell
        $desktopLink = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "FREGONATOR.lnk")
        $shortcut = $WshShell.CreateShortcut($desktopLink)
        $shortcut.TargetPath = $batPath
        $shortcut.WorkingDirectory = $installPath
        if (Test-Path $icoPath) { $shortcut.IconLocation = $icoPath }
        $shortcut.Save()
        Write-Host "        OK - $desktopLink" -ForegroundColor Green
    } else {
        Write-Host "        Warning: FREGONATOR.bat not found" -ForegroundColor Yellow
        Write-Host "        Files in $installPath :" -ForegroundColor Gray
        Get-ChildItem $installPath -Name | ForEach-Object { Write-Host "          $_" -ForegroundColor Gray }
    }

    # Cleanup
    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "  ==========================================" -ForegroundColor Green
    Write-Host "    FREGONATOR installed successfully!" -ForegroundColor Green
    Write-Host "  ==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Location: $installPath" -ForegroundColor White
    Write-Host "  Shortcut: Desktop" -ForegroundColor White
    Write-Host ""
    Write-Host "  Double-click FREGONATOR on your Desktop to run!" -ForegroundColor Cyan
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Try: https://github.com/dthcst/fregonator" -ForegroundColor Yellow
    Write-Host ""
}
