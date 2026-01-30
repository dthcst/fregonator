<#
    FREGONATOR v3.3 - Instalador Nativo PowerShell
    - Instala en Program Files
    - Crea acceso directo en Escritorio y Menu Inicio
    - Registra en "Agregar o quitar programas"
    - Desinstalador incluido
#>

param(
    [switch]$Uninstall,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURACION
# ============================================================================
$AppName = "FREGONATOR"
$AppVersion = "3.4.0"
$AppPublisher = "Costa da Morte / Claude Code"
$AppURL = "https://fregonator.com"
$InstallDir = "$env:ProgramFiles\$AppName"
$UninstallRegKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppName"

# Obtener directorio del instalador
$InstallerDir = $PSScriptRoot
if (-not $InstallerDir) { $InstallerDir = Split-Path -Parent $MyInvocation.MyCommand.Path }

# ============================================================================
# VERIFICAR ADMIN
# ============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Reiniciando como administrador..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" $(if($Uninstall){'-Uninstall'}) $(if($Silent){'-Silent'})" -Verb RunAs
    exit
}

# ============================================================================
# FUNCIONES UI
# ============================================================================
function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "    ========================================================" -ForegroundColor Cyan
    Write-Host "         FREGONATOR v$AppVersion - INSTALADOR                " -ForegroundColor Cyan
    Write-Host "    ========================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Progress($Step, $Total, $Message) {
    $percent = [int](($Step / $Total) * 100)
    $bar = "#" * [int]($percent / 5) + "-" * (20 - [int]($percent / 5))
    Write-Host "    [$bar] $percent% - $Message" -ForegroundColor Gray
}

# ============================================================================
# DESINSTALAR
# ============================================================================
if ($Uninstall) {
    Show-Header
    Write-Host "    DESINSTALANDO FREGONATOR..." -ForegroundColor Yellow
    Write-Host ""

    # Eliminar archivos
    if (Test-Path $InstallDir) {
        Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "    [OK] Archivos eliminados" -ForegroundColor Green
    }

    # Eliminar acceso directo escritorio
    $desktopShortcut = "$env:PUBLIC\Desktop\$AppName.lnk"
    if (Test-Path $desktopShortcut) {
        Remove-Item $desktopShortcut -Force
        Write-Host "    [OK] Acceso directo escritorio eliminado" -ForegroundColor Green
    }

    # Eliminar acceso directo menu inicio
    $startMenuFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$AppName"
    if (Test-Path $startMenuFolder) {
        Remove-Item $startMenuFolder -Recurse -Force
        Write-Host "    [OK] Carpeta menu inicio eliminada" -ForegroundColor Green
    }

    # Eliminar registro
    if (Test-Path $UninstallRegKey) {
        Remove-Item $UninstallRegKey -Force
        Write-Host "    [OK] Registro de Windows limpiado" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "    ========================================================" -ForegroundColor Green
    Write-Host "         FREGONATOR DESINSTALADO CORRECTAMENTE              " -ForegroundColor Green
    Write-Host "    ========================================================" -ForegroundColor Green
    Write-Host ""

    if (-not $Silent) {
        Write-Host "    Presiona cualquier tecla para cerrar..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit 0
}

# ============================================================================
# INSTALAR
# ============================================================================
Show-Header

# Archivos requeridos
$archivos = @(
    "FREGONATOR.bat",
    "Fregonator.ps1",
    "Fregonator-Launcher.ps1",
    "Fregonator-Monitor.ps1",
    "Logo-Fregonator-001.png",
    "fregonator.ico",
    "LICENCIA.txt"
)

# Verificar archivos
Write-Host "    Verificando archivos..." -ForegroundColor Yellow
$faltantes = @()
foreach ($archivo in $archivos) {
    if (-not (Test-Path "$InstallerDir\$archivo")) {
        $faltantes += $archivo
    }
}
if (-not (Test-Path "$InstallerDir\_SONIDOS\bark.wav")) { $faltantes += "_SONIDOS\bark.wav" }

if ($faltantes.Count -gt 0) {
    Write-Host ""
    Write-Host "    [ERROR] Faltan archivos:" -ForegroundColor Red
    $faltantes | ForEach-Object { Write-Host "      - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "    Asegurate de ejecutar el instalador desde la carpeta" -ForegroundColor Yellow
    Write-Host "    donde estan todos los archivos de FREGONATOR." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host "    [OK] Todos los archivos encontrados" -ForegroundColor Green
Write-Host ""

# Confirmacion
if (-not $Silent) {
    Write-Host "    Se instalara FREGONATOR en:" -ForegroundColor White
    Write-Host "    $InstallDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Se crearan:" -ForegroundColor White
    Write-Host "    - Acceso directo en Escritorio" -ForegroundColor Gray
    Write-Host "    - Entrada en Menu Inicio" -ForegroundColor Gray
    Write-Host "    - Entrada en 'Agregar o quitar programas'" -ForegroundColor Gray
    Write-Host ""
    $resp = Read-Host "    Continuar? (S/N)"
    if ($resp -notmatch "^[SsYy]") {
        Write-Host "    Instalacion cancelada." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# PASO 1: Crear directorio
Show-Progress 1 5 "Creando directorio..."
if (Test-Path $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force
}
New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
New-Item -Path "$InstallDir\_SONIDOS" -ItemType Directory -Force | Out-Null
New-Item -Path "$InstallDir\_FUENTES\citaro_voor_dubbele_hoogte_breed" -ItemType Directory -Force | Out-Null

# PASO 2: Copiar archivos
Show-Progress 2 5 "Copiando archivos..."
foreach ($archivo in $archivos) {
    Copy-Item "$InstallerDir\$archivo" "$InstallDir\$archivo" -Force
}
Copy-Item "$InstallerDir\_SONIDOS\*" "$InstallDir\_SONIDOS\" -Force -ErrorAction SilentlyContinue
if (Test-Path "$InstallerDir\_FUENTES\citaro_voor_dubbele_hoogte_breed") {
    Copy-Item "$InstallerDir\_FUENTES\citaro_voor_dubbele_hoogte_breed\*" "$InstallDir\_FUENTES\citaro_voor_dubbele_hoogte_breed\" -Force -ErrorAction SilentlyContinue
}
if (Test-Path "$InstallerDir\README.md") {
    Copy-Item "$InstallerDir\README.md" "$InstallDir\README.md" -Force
}

# Copiar el propio instalador como desinstalador
Copy-Item $PSCommandPath "$InstallDir\Uninstall.ps1" -Force

# PASO 3: Crear acceso directo escritorio
Show-Progress 3 5 "Creando acceso directo escritorio..."
$WshShell = New-Object -ComObject WScript.Shell
$desktopShortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\$AppName.lnk")
$desktopShortcut.TargetPath = "$InstallDir\FREGONATOR.bat"
$desktopShortcut.WorkingDirectory = $InstallDir
$desktopShortcut.IconLocation = "$InstallDir\fregonator.ico"
$desktopShortcut.Description = "FREGONATOR - Optimizador de PC"
$desktopShortcut.Save()

# PASO 4: Crear entrada menu inicio
Show-Progress 4 5 "Creando entrada menu inicio..."
$startMenuFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$AppName"
New-Item -Path $startMenuFolder -ItemType Directory -Force | Out-Null

$startShortcut = $WshShell.CreateShortcut("$startMenuFolder\$AppName.lnk")
$startShortcut.TargetPath = "$InstallDir\FREGONATOR.bat"
$startShortcut.WorkingDirectory = $InstallDir
$startShortcut.IconLocation = "$InstallDir\fregonator.ico"
$startShortcut.Description = "FREGONATOR - Optimizador de PC"
$startShortcut.Save()

# Crear acceso directo a desinstalador
$uninstallShortcut = $WshShell.CreateShortcut("$startMenuFolder\Desinstalar $AppName.lnk")
$uninstallShortcut.TargetPath = "powershell.exe"
$uninstallShortcut.Arguments = "-ExecutionPolicy Bypass -File `"$InstallDir\Uninstall.ps1`" -Uninstall"
$uninstallShortcut.WorkingDirectory = $InstallDir
$uninstallShortcut.IconLocation = "$InstallDir\fregonator.ico"
$uninstallShortcut.Description = "Desinstalar FREGONATOR"
$uninstallShortcut.Save()

# PASO 5: Registrar en Windows
Show-Progress 5 5 "Registrando en Windows..."
$uninstallCmd = "powershell.exe -ExecutionPolicy Bypass -File `"$InstallDir\Uninstall.ps1`" -Uninstall -Silent"

New-Item -Path $UninstallRegKey -Force | Out-Null
Set-ItemProperty -Path $UninstallRegKey -Name "DisplayName" -Value $AppName
Set-ItemProperty -Path $UninstallRegKey -Name "DisplayVersion" -Value $AppVersion
Set-ItemProperty -Path $UninstallRegKey -Name "Publisher" -Value $AppPublisher
Set-ItemProperty -Path $UninstallRegKey -Name "URLInfoAbout" -Value $AppURL
Set-ItemProperty -Path $UninstallRegKey -Name "InstallLocation" -Value $InstallDir
Set-ItemProperty -Path $UninstallRegKey -Name "UninstallString" -Value $uninstallCmd
Set-ItemProperty -Path $UninstallRegKey -Name "DisplayIcon" -Value "$InstallDir\fregonator.ico"
Set-ItemProperty -Path $UninstallRegKey -Name "NoModify" -Value 1 -Type DWord
Set-ItemProperty -Path $UninstallRegKey -Name "NoRepair" -Value 1 -Type DWord

# Calcular tamano aproximado
$size = (Get-ChildItem $InstallDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB
Set-ItemProperty -Path $UninstallRegKey -Name "EstimatedSize" -Value ([int]$size) -Type DWord

# ============================================================================
# COMPLETADO
# ============================================================================
Write-Host ""
Write-Host "    ========================================================" -ForegroundColor Green
Write-Host "         FREGONATOR INSTALADO CORRECTAMENTE                  " -ForegroundColor Green
Write-Host "    ========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "    Instalado en: $InstallDir" -ForegroundColor Gray
Write-Host ""
Write-Host "    Puedes ejecutar FREGONATOR desde:" -ForegroundColor White
Write-Host "    - Icono en el Escritorio" -ForegroundColor Cyan
Write-Host "    - Menu Inicio > FREGONATOR" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Para desinstalar:" -ForegroundColor White
Write-Host "    - Configuracion > Aplicaciones > FREGONATOR > Desinstalar" -ForegroundColor Gray
Write-Host "    - O ejecuta: $InstallDir\Uninstall.ps1 -Uninstall" -ForegroundColor Gray
Write-Host ""

if (-not $Silent) {
    $resp = Read-Host "    Ejecutar FREGONATOR ahora? (S/N)"
    if ($resp -match "^[SsYy]") {
        Start-Process "$InstallDir\FREGONATOR.bat" -WorkingDirectory $InstallDir
    }
}

Write-Host ""
Write-Host "    Gracias por instalar FREGONATOR!" -ForegroundColor Cyan
Write-Host ""
