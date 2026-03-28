<#
    Fregonator v6.0 - Instalador Nativo PowerShell
    - Instala en Program Files
    - Crea acceso directo en Escritorio y Menu Inicio
    - Registra en "Agregar o quitar programas"
    - Desinstalador incluido
    - Multi-idioma: ES/EN/GL con deteccion automatica
#>

param(
    [switch]$Uninstall,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURACION
# ============================================================================
$AppName = "Fregonator"
$AppVersion = "6.0"
$AppPublisher = "Costa da Morte / Claude Code"
$AppURL = "https://fregonator.com"
$InstallDir = "$env:ProgramFiles\$AppName"
$UninstallRegKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppName"

# Obtener directorio del instalador
$InstallerDir = $PSScriptRoot
if (-not $InstallerDir) { $InstallerDir = Split-Path -Parent $MyInvocation.MyCommand.Path }

# ============================================================================
# SISTEMA MULTI-IDIOMA (es/en/gl)
# ============================================================================
$script:IDIOMAS = @{
    es = @{
        header              = "FREGONATOR v{0} - INSTALADOR"
        reiniciandoAdmin    = "Reiniciando como administrador..."
        verificandoArchivos = "Verificando archivos..."
        archivosOk          = "Todos los archivos encontrados"
        faltanArchivos      = "Faltan archivos:"
        asegurateEjecutar   = "Asegurate de ejecutar el instalador desde la carpeta"
        dondeEstanArchivos  = "donde estan todos los archivos de FREGONATOR."
        seInstalara         = "Se instalara FREGONATOR en:"
        seCrearan           = "Se crearan:"
        accesoEscritorio    = "Acceso directo en Escritorio"
        entradaMenuInicio   = "Entrada en Menu Inicio"
        entradaAgregar      = "Entrada en 'Agregar o quitar programas'"
        continuar           = "Continuar? (S/N)"
        confirmPattern      = "^[SsYy]"
        cancelada           = "Instalacion cancelada."
        creandoDir          = "Creando directorio..."
        copiandoArchivos    = "Copiando archivos..."
        creandoAccesoEscr   = "Creando acceso directo escritorio..."
        descripcionApp      = "FREGONATOR - Optimizador de PC"
        creandoMenuInicio   = "Creando entrada menu inicio..."
        desinstalarNombre   = "Desinstalar {0}"
        descripcionDesinst  = "Desinstalar FREGONATOR"
        registrandoWindows  = "Registrando en Windows..."
        instaladoOk         = "FREGONATOR INSTALADO CORRECTAMENTE"
        instaladoEn         = "Instalado en:"
        ejecutarDesde       = "Puedes ejecutar FREGONATOR desde:"
        iconoEscritorio     = "Icono en el Escritorio"
        menuInicioFregon    = "Menu Inicio > FREGONATOR"
        paraDesinstalar     = "Para desinstalar:"
        desinstConfigApps   = "Configuracion > Aplicaciones > FREGONATOR > Desinstalar"
        desinstOEjecuta     = "O ejecuta:"
        ejecutarAhora       = "Ejecutar FREGONATOR ahora? (S/N)"
        graciasInstalar     = "Gracias por instalar FREGONATOR!"
        desinstalando       = "DESINSTALANDO FREGONATOR..."
        archivosEliminados  = "Archivos eliminados"
        accesoEscrEliminado = "Acceso directo escritorio eliminado"
        carpetaMenuElim     = "Carpeta menu inicio eliminada"
        registroLimpiado    = "Registro de Windows limpiado"
        desinstaladoOk      = "FREGONATOR DESINSTALADO CORRECTAMENTE"
        presionaTecla       = "Presiona cualquier tecla para cerrar..."
    }
    en = @{
        header              = "FREGONATOR v{0} - INSTALLER"
        reiniciandoAdmin    = "Restarting as administrator..."
        verificandoArchivos = "Verifying files..."
        archivosOk          = "All files found"
        faltanArchivos      = "Missing files:"
        asegurateEjecutar   = "Make sure to run the installer from the folder"
        dondeEstanArchivos  = "where all FREGONATOR files are located."
        seInstalara         = "FREGONATOR will be installed in:"
        seCrearan           = "The following will be created:"
        accesoEscritorio    = "Desktop shortcut"
        entradaMenuInicio   = "Start Menu entry"
        entradaAgregar      = "Entry in 'Add or remove programs'"
        continuar           = "Continue? (Y/N)"
        confirmPattern      = "^[YySs]"
        cancelada           = "Installation cancelled."
        creandoDir          = "Creating directory..."
        copiandoArchivos    = "Copying files..."
        creandoAccesoEscr   = "Creating desktop shortcut..."
        descripcionApp      = "FREGONATOR - PC Optimizer"
        creandoMenuInicio   = "Creating Start Menu entry..."
        desinstalarNombre   = "Uninstall {0}"
        descripcionDesinst  = "Uninstall FREGONATOR"
        registrandoWindows  = "Registering in Windows..."
        instaladoOk         = "FREGONATOR INSTALLED SUCCESSFULLY"
        instaladoEn         = "Installed in:"
        ejecutarDesde       = "You can run FREGONATOR from:"
        iconoEscritorio     = "Desktop icon"
        menuInicioFregon    = "Start Menu > FREGONATOR"
        paraDesinstalar     = "To uninstall:"
        desinstConfigApps   = "Settings > Apps > FREGONATOR > Uninstall"
        desinstOEjecuta     = "Or run:"
        ejecutarAhora       = "Run FREGONATOR now? (Y/N)"
        graciasInstalar     = "Thanks for installing FREGONATOR!"
        desinstalando       = "UNINSTALLING FREGONATOR..."
        archivosEliminados  = "Files removed"
        accesoEscrEliminado = "Desktop shortcut removed"
        carpetaMenuElim     = "Start Menu folder removed"
        registroLimpiado    = "Windows registry cleaned"
        desinstaladoOk      = "FREGONATOR UNINSTALLED SUCCESSFULLY"
        presionaTecla       = "Press any key to close..."
    }
    gl = @{
        header              = "FREGONATOR v{0} - INSTALADOR"
        reiniciandoAdmin    = "Reiniciando como administrador..."
        verificandoArchivos = "Verificando ficheiros..."
        archivosOk          = "Todos os ficheiros atopados"
        faltanArchivos      = "Faltan ficheiros:"
        asegurateEjecutar   = "Asegurate de executar o instalador desde o cartafol"
        dondeEstanArchivos  = "onde estan todos os ficheiros de FREGONATOR."
        seInstalara         = "FREGONATOR instalarase en:"
        seCrearan           = "Crearanse:"
        accesoEscritorio    = "Acceso directo no Escritorio"
        entradaMenuInicio   = "Entrada no Menu Inicio"
        entradaAgregar      = "Entrada en 'Engadir ou quitar programas'"
        continuar           = "Continuar? (S/N)"
        confirmPattern      = "^[SsYy]"
        cancelada           = "Instalacion cancelada."
        creandoDir          = "Creando directorio..."
        copiandoArchivos    = "Copiando ficheiros..."
        creandoAccesoEscr   = "Creando acceso directo escritorio..."
        descripcionApp      = "FREGONATOR - Optimizador de PC"
        creandoMenuInicio   = "Creando entrada menu inicio..."
        desinstalarNombre   = "Desinstalar {0}"
        descripcionDesinst  = "Desinstalar FREGONATOR"
        registrandoWindows  = "Rexistrando en Windows..."
        instaladoOk         = "FREGONATOR INSTALADO CORRECTAMENTE"
        instaladoEn         = "Instalado en:"
        ejecutarDesde       = "Podes executar FREGONATOR desde:"
        iconoEscritorio     = "Icona no Escritorio"
        menuInicioFregon    = "Menu Inicio > FREGONATOR"
        paraDesinstalar     = "Para desinstalar:"
        desinstConfigApps   = "Configuracion > Aplicacions > FREGONATOR > Desinstalar"
        desinstOEjecuta     = "Ou executa:"
        ejecutarAhora       = "Executar FREGONATOR agora? (S/N)"
        graciasInstalar     = "Grazas por instalar FREGONATOR!"
        desinstalando       = "DESINSTALANDO FREGONATOR..."
        archivosEliminados  = "Ficheiros eliminados"
        accesoEscrEliminado = "Acceso directo escritorio eliminado"
        carpetaMenuElim     = "Cartafol menu inicio eliminado"
        registroLimpiado    = "Rexistro de Windows limpado"
        desinstaladoOk      = "FREGONATOR DESINSTALADO CORRECTAMENTE"
        presionaTecla       = "Preme calquera tecla para pechar..."
    }
}

# Funcion para obtener traduccion
function T {
    param([string]$Key)
    if ($script:IDIOMAS[$script:Idioma] -and $script:IDIOMAS[$script:Idioma][$Key]) {
        return $script:IDIOMAS[$script:Idioma][$Key]
    }
    # Fallback a español
    if ($script:IDIOMAS["es"][$Key]) {
        return $script:IDIOMAS["es"][$Key]
    }
    return $Key
}

# Detectar idioma del sistema
function Get-SystemLanguage {
    # Primero verificar preferencia guardada por Fregonator
    $configFile = "$env:LOCALAPPDATA\FREGONATOR\lang.txt"
    if (Test-Path $configFile) {
        $saved = (Get-Content $configFile -Raw).Trim()
        if ($saved -eq "en" -or $saved -eq "es" -or $saved -eq "gl") { return $saved }
    }

    # Usar UICulture (idioma de interfaz) en lugar de Culture (formato regional)
    $uiCulture = (Get-UICulture).Name
    $culture = (Get-Culture).Name

    foreach ($lang in @($uiCulture, $culture)) {
        switch -Wildcard ($lang) {
            "en*" { return "en" }
            "es*" { return "es" }
            "gl*" { return "gl" }
        }
    }

    # Default internacional
    return "en"
}

$script:Idioma = Get-SystemLanguage

# ============================================================================
# VERIFICAR ADMIN
# ============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host (T "reiniciandoAdmin") -ForegroundColor Yellow
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
    Write-Host "         $((T 'header') -f $AppVersion)                " -ForegroundColor Cyan
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
    Write-Host "    $(T 'desinstalando')" -ForegroundColor Yellow
    Write-Host ""

    # Eliminar archivos
    if (Test-Path $InstallDir) {
        Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "    [OK] $(T 'archivosEliminados')" -ForegroundColor Green
    }

    # Eliminar acceso directo escritorio
    $desktopShortcut = "$env:PUBLIC\Desktop\$AppName.lnk"
    if (Test-Path $desktopShortcut) {
        Remove-Item $desktopShortcut -Force
        Write-Host "    [OK] $(T 'accesoEscrEliminado')" -ForegroundColor Green
    }

    # Eliminar acceso directo menu inicio
    $startMenuFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$AppName"
    if (Test-Path $startMenuFolder) {
        Remove-Item $startMenuFolder -Recurse -Force
        Write-Host "    [OK] $(T 'carpetaMenuElim')" -ForegroundColor Green
    }

    # Eliminar registro
    if (Test-Path $UninstallRegKey) {
        Remove-Item $UninstallRegKey -Force
        Write-Host "    [OK] $(T 'registroLimpiado')" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "    ========================================================" -ForegroundColor Green
    Write-Host "         $(T 'desinstaladoOk')              " -ForegroundColor Green
    Write-Host "    ========================================================" -ForegroundColor Green
    Write-Host ""

    if (-not $Silent) {
        Write-Host "    $(T 'presionaTecla')"
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
Write-Host "    $(T 'verificandoArchivos')" -ForegroundColor Yellow
$faltantes = @()
foreach ($archivo in $archivos) {
    if (-not (Test-Path "$InstallerDir\$archivo")) {
        $faltantes += $archivo
    }
}
if (-not (Test-Path "$InstallerDir\sounds\bark.wav")) { $faltantes += "sounds\bark.wav" }

if ($faltantes.Count -gt 0) {
    Write-Host ""
    Write-Host "    [ERROR] $(T 'faltanArchivos')" -ForegroundColor Red
    $faltantes | ForEach-Object { Write-Host "      - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "    $(T 'asegurateEjecutar')" -ForegroundColor Yellow
    Write-Host "    $(T 'dondeEstanArchivos')" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host "    [OK] $(T 'archivosOk')" -ForegroundColor Green
Write-Host ""

# Confirmacion
if (-not $Silent) {
    Write-Host "    $(T 'seInstalara')" -ForegroundColor White
    Write-Host "    $InstallDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    $(T 'seCrearan')" -ForegroundColor White
    Write-Host "    - $(T 'accesoEscritorio')" -ForegroundColor Gray
    Write-Host "    - $(T 'entradaMenuInicio')" -ForegroundColor Gray
    Write-Host "    - $(T 'entradaAgregar')" -ForegroundColor Gray
    Write-Host ""
    $resp = Read-Host "    $(T 'continuar')"
    if ($resp -notmatch (T 'confirmPattern')) {
        Write-Host "    $(T 'cancelada')" -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# PASO 1: Crear directorio
Show-Progress 1 5 (T "creandoDir")
if (Test-Path $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force
}
New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
New-Item -Path "$InstallDir\sounds" -ItemType Directory -Force | Out-Null
New-Item -Path "$InstallDir\_FUENTES\citaro_voor_dubbele_hoogte_breed" -ItemType Directory -Force | Out-Null

# PASO 2: Copiar archivos
Show-Progress 2 5 (T "copiandoArchivos")
foreach ($archivo in $archivos) {
    Copy-Item "$InstallerDir\$archivo" "$InstallDir\$archivo" -Force
}
Copy-Item "$InstallerDir\sounds\*" "$InstallDir\sounds\" -Force -ErrorAction SilentlyContinue
if (Test-Path "$InstallerDir\_FUENTES\citaro_voor_dubbele_hoogte_breed") {
    Copy-Item "$InstallerDir\_FUENTES\citaro_voor_dubbele_hoogte_breed\*" "$InstallDir\_FUENTES\citaro_voor_dubbele_hoogte_breed\" -Force -ErrorAction SilentlyContinue
}
if (Test-Path "$InstallerDir\README.md") {
    Copy-Item "$InstallerDir\README.md" "$InstallDir\README.md" -Force
}

# Copiar el propio instalador como desinstalador
Copy-Item $PSCommandPath "$InstallDir\Uninstall.ps1" -Force

# PASO 3: Crear acceso directo escritorio
Show-Progress 3 5 (T "creandoAccesoEscr")
$WshShell = New-Object -ComObject WScript.Shell
$desktopShortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\$AppName.lnk")
$desktopShortcut.TargetPath = "$InstallDir\FREGONATOR.bat"
$desktopShortcut.WorkingDirectory = $InstallDir
$desktopShortcut.IconLocation = "$InstallDir\fregonator.ico"
$desktopShortcut.Description = T "descripcionApp"
$desktopShortcut.Save()

# PASO 4: Crear entrada menu inicio
Show-Progress 4 5 (T "creandoMenuInicio")
$startMenuFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$AppName"
New-Item -Path $startMenuFolder -ItemType Directory -Force | Out-Null

$startShortcut = $WshShell.CreateShortcut("$startMenuFolder\$AppName.lnk")
$startShortcut.TargetPath = "$InstallDir\FREGONATOR.bat"
$startShortcut.WorkingDirectory = $InstallDir
$startShortcut.IconLocation = "$InstallDir\fregonator.ico"
$startShortcut.Description = T "descripcionApp"
$startShortcut.Save()

# Crear acceso directo a desinstalador
$uninstallLinkName = (T "desinstalarNombre") -f $AppName
$uninstallShortcut = $WshShell.CreateShortcut("$startMenuFolder\$uninstallLinkName.lnk")
$uninstallShortcut.TargetPath = "powershell.exe"
$uninstallShortcut.Arguments = "-ExecutionPolicy Bypass -File `"$InstallDir\Uninstall.ps1`" -Uninstall"
$uninstallShortcut.WorkingDirectory = $InstallDir
$uninstallShortcut.IconLocation = "$InstallDir\fregonator.ico"
$uninstallShortcut.Description = T "descripcionDesinst"
$uninstallShortcut.Save()

# PASO 5: Registrar en Windows
Show-Progress 5 5 (T "registrandoWindows")
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
Write-Host "         $(T 'instaladoOk')                  " -ForegroundColor Green
Write-Host "    ========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "    $(T 'instaladoEn') $InstallDir" -ForegroundColor Gray
Write-Host ""
Write-Host "    $(T 'ejecutarDesde')" -ForegroundColor White
Write-Host "    - $(T 'iconoEscritorio')" -ForegroundColor Cyan
Write-Host "    - $(T 'menuInicioFregon')" -ForegroundColor Cyan
Write-Host ""
Write-Host "    $(T 'paraDesinstalar')" -ForegroundColor White
Write-Host "    - $(T 'desinstConfigApps')" -ForegroundColor Gray
Write-Host "    - $(T 'desinstOEjecuta') $InstallDir\Uninstall.ps1 -Uninstall" -ForegroundColor Gray
Write-Host ""

if (-not $Silent) {
    $resp = Read-Host "    $(T 'ejecutarAhora')"
    if ($resp -match (T 'confirmPattern')) {
        Start-Process "$InstallDir\FREGONATOR.bat" -WorkingDirectory $InstallDir
    }
}

Write-Host ""
Write-Host "    $(T 'graciasInstalar')" -ForegroundColor Cyan
Write-Host ""
