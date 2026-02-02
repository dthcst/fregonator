# FREGONATOR Quick Installer
# Usage: irm https://raw.githubusercontent.com/dthcst/fregonator/main/install.ps1 | iex

$repo = "dthcst/fregonator"
$installPath = "$env:ProgramFiles\FREGONATOR"

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
Write-Host "  Quick Installer - https://fregonator.com" -ForegroundColor White
Write-Host ""

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "  [!] Admin required. Relaunching..." -ForegroundColor Yellow
    Write-Host ""
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/$repo/main/install.ps1 | iex; Read-Host 'Press Enter'`"" -Verb RunAs
    return
}

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

    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }
    Copy-Item "$sourceDir\*" -Destination $installPath -Recurse -Force
    Write-Host "        OK" -ForegroundColor Green

    # Shortcuts
    Write-Host "  [4/4] Creating shortcuts..." -ForegroundColor Yellow
    $WshShell = New-Object -ComObject WScript.Shell

    $desktopLink = "$env:USERPROFILE\Desktop\FREGONATOR.lnk"
    $shortcut = $WshShell.CreateShortcut($desktopLink)
    $shortcut.TargetPath = "$installPath\FREGONATOR.bat"
    $shortcut.WorkingDirectory = $installPath
    $shortcut.IconLocation = "$installPath\fregonator.ico"
    $shortcut.Save()

    $startMenu = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\FREGONATOR.lnk"
    $shortcut2 = $WshShell.CreateShortcut($startMenu)
    $shortcut2.TargetPath = "$installPath\FREGONATOR.bat"
    $shortcut2.WorkingDirectory = $installPath
    $shortcut2.IconLocation = "$installPath\fregonator.ico"
    $shortcut2.Save()
    Write-Host "        OK" -ForegroundColor Green

    # Cleanup
    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Green
    Write-Host "     FREGONATOR installed successfully!" -ForegroundColor Green
    Write-Host "  ============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Location: $installPath" -ForegroundColor White
    Write-Host "  Shortcut on Desktop + Start Menu" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Download manually: https://fregonator.com" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "  Press Enter to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
