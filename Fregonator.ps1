# =============================================================================
# FREGONATOR v4.0 - OPTIMIZADOR DE PC
# El modulo DEFINITIVO: Limpieza Rapida / Avanzada / Profunda
# 100% nativo Windows - Sin dependencias externas
# www.fregonator.com | ARCAMIA-MEMMEM
# =============================================================================
# MODULARIZADO 2026-01-24:
#   - Fregonator-Config.ps1 (configuracion, helpers)
#   - Fregonator-UI.ps1 (logo, menus)
#   - Fregonator-Logs.ps1 (logging, HTML export)
#   - Fregonator-Limpieza.ps1 (funciones limpieza basica)
#   - Fregonator-Avanzado.ps1 (funciones avanzadas)
#   - Fregonator.Tests.ps1 (tests Pester)
# FUSIONADO 2026-01-23:
#   - Limpiar-Registro.ps1 (MRU, WordWheelQuery, MUICache)
#   - Tuning-Total.ps1 (Matar procesos, CPU 100%, cache ARP)
#   - Mantenimiento-Total.ps1 (Telemetria OFF, efectos visuales)
#   + DISM RestoreHealth + SFC scannow
# =============================================================================

# =============================================================================
# PARAMETROS - Modo silencioso para scripts y automatizacion
# =============================================================================
param(
    [switch]$Silent,        # Ejecuta UN CLICK sin UI, ideal para scripts
    [switch]$Avanzada,      # Ejecuta UN CLICK AVANZADA en modo silencioso
    [switch]$AutoRapida,    # Ejecuta Limpieza Rapida con UI completa (para launcher)
    [switch]$AutoAvanzada,  # Ejecuta Limpieza Avanzada con UI completa (para launcher)
    [switch]$Help           # Muestra ayuda de parametros
)

# Mostrar ayuda si se solicita
if ($Help) {
    Write-Host ""
    Write-Host "  FREGONATOR v4.0 - Optimizador de PC" -ForegroundColor Cyan
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  USO:" -ForegroundColor Yellow
    Write-Host "    .\Fregonator.ps1              # Modo interactivo (menu)"
    Write-Host "    .\Fregonator.ps1 -Silent      # UN CLICK Rapida sin UI"
    Write-Host "    .\Fregonator.ps1 -Avanzada    # UN CLICK Avanzada sin UI"
    Write-Host "    .\Fregonator.ps1 -Help        # Muestra esta ayuda"
    Write-Host ""
    Write-Host "  EJEMPLOS:" -ForegroundColor Yellow
    Write-Host "    # Ejecutar limpieza rapida desde script:"
    Write-Host "    powershell -ExecutionPolicy Bypass -File Fregonator.ps1 -Silent"
    Write-Host ""
    Write-Host "    # Tarea programada para limpieza nocturna:"
    Write-Host "    powershell -ExecutionPolicy Bypass -File Fregonator.ps1 -Avanzada"
    Write-Host ""
    exit 0
}

# Guardar modo silencioso en variable de script
$script:SilentMode = $Silent -or $Avanzada
# Modo GUI: viene del Launcher, motor oculto, sin interaccion
$script:ModoGUI = $AutoRapida -or $AutoAvanzada

# =============================================================================
# AUTO-ELEVACION A ADMINISTRADOR
# =============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Reconstruir argumentos incluyendo los parametros
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Silent) { $arguments += " -Silent" }
    if ($Avanzada) { $arguments += " -Avanzada" }
    if ($AutoRapida) { $arguments += " -AutoRapida" }
    if ($AutoAvanzada) { $arguments += " -AutoAvanzada" }
    try {
        Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    } catch {
        Write-Host ""
        Write-Host "  [ERROR] Se requieren permisos de Administrador" -ForegroundColor Red
        Write-Host "  Click derecho -> Ejecutar como administrador" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  ENTER para salir"
    }
    exit
}

Clear-Host

# =============================================================================
# OCULTAR CONSOLA DE BARRA DE TAREAS (pero mantener visible en pantalla)
# Solo en modo GUI (cuando viene del Launcher)
# =============================================================================
if ($script:ModoGUI) {
    # Columnas suficientes para el logo ASCII grande
    cmd /c "mode con cols=130"
    Start-Sleep -Milliseconds 200

    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class ConsoleWindow {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
        [DllImport("user32.dll")]
        public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
        [DllImport("user32.dll")]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
        [DllImport("user32.dll")]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT { public int Left, Top, Right, Bottom; }

        private const int GWL_EXSTYLE = -20;
        private const int WS_EX_APPWINDOW = 0x40000;
        private const int WS_EX_TOOLWINDOW = 0x80;
        private const uint SWP_NOZORDER = 0x4;
        private const uint SWP_FRAMECHANGED = 0x20;

        public static void Setup(int screenX, int screenY, int screenWidth, int screenHeight) {
            IntPtr hwnd = GetConsoleWindow();

            // Ocultar de barra de tareas
            int style = GetWindowLong(hwnd, GWL_EXSTYLE);
            style = (style & ~WS_EX_APPWINDOW) | WS_EX_TOOLWINDOW;
            SetWindowLong(hwnd, GWL_EXSTYLE, style);
            SetWindowPos(hwnd, IntPtr.Zero, 0, 0, 0, 0, 0x2 | 0x1 | SWP_NOZORDER | SWP_FRAMECHANGED);

            // Tamaño: 130 cols = ~1040px, altura para contenido
            int terminalWidth = 1040;
            int terminalHeight = 720;

            // CENTRAR ambas ventanas juntas en monitor principal
            int monitorWidth = 480;
            int gap = 10;
            int totalWidth = terminalWidth + gap + monitorWidth;
            int posX = screenX + (screenWidth - totalWidth) / 2;
            int posY = screenY + (screenHeight - terminalHeight) / 2;
            MoveWindow(hwnd, posX, posY, terminalWidth, terminalHeight, true);
        }
    }
"@
    Add-Type -AssemblyName System.Windows.Forms
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    [ConsoleWindow]::Setup($screen.X, $screen.Y, $screen.Width, $screen.Height)
}

# NOTA: Mutex eliminado en v3.1 - causaba bloqueos al volver al menu

# =============================================================================
# FUNCIONES HELPER - Consola segura (para GUI y stdin redirigido)
# =============================================================================
function Test-ConsolaInteractiva {
    try {
        $null = [Console]::KeyAvailable
        return $true
    } catch {
        return $false
    }
}

function Get-CursorTopSafe {
    if (Test-ConsolaInteractiva) {
        try { return [Console]::CursorTop } catch { return 0 }
    }
    return 0
}

function Set-CursorPositionSafe {
    param([int]$X, [int]$Y)
    if (Test-ConsolaInteractiva) {
        try { [Console]::SetCursorPosition($X, $Y) } catch {}
    }
}

$script:EsConsolaInteractiva = Test-ConsolaInteractiva

# Configurar encoding UTF-8 para la consola
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 2>&1 | Out-Null
} catch {}

# Ocultar barras de progreso feas de PowerShell
$ProgressPreference = 'SilentlyContinue'

# FREGONATOR es 100% standalone - no requiere dependencias externas
# Las funciones necesarias estan incluidas en este archivo

# =============================================================================
# MONITOR DE PROGRESO - Escribe JSON para GUI externa
# =============================================================================
$script:MonitorFile = "$env:PUBLIC\fregonator_progress.json"
$script:MonitorData = @{
    Etapa = "Iniciando"
    Progreso = 0
    ArchivoActual = ""
    ArchivosProcesados = 0
    TotalTareas = 8
    EspacioLiberado = 0
    Log = ""
    Terminado = $false
}

function Update-Monitor {
    param(
        [string]$Etapa,
        [int]$Progreso,
        [string]$Archivo,
        [int]$Archivos,
        [int]$Total,
        [double]$EspacioMB,
        [string]$Log,
        [switch]$Terminado
    )

    if ($Etapa) { $script:MonitorData.Etapa = $Etapa }
    if ($Progreso -ge 0) { $script:MonitorData.Progreso = $Progreso }
    if ($Archivo) { $script:MonitorData.ArchivoActual = $Archivo }
    if ($Archivos -ge 0) { $script:MonitorData.ArchivosProcesados = $Archivos }
    if ($Total -gt 0) { $script:MonitorData.TotalTareas = $Total }
    if ($EspacioMB -ge 0) { $script:MonitorData.EspacioLiberado = $EspacioMB }
    if ($Log) { $script:MonitorData.Log = $Log }
    if ($Terminado) { $script:MonitorData.Terminado = $true }

    try {
        $script:MonitorData | ConvertTo-Json -Compress | Out-File $script:MonitorFile -Encoding UTF8 -Force
    } catch {}
}

# Inicializar monitor
Update-Monitor -Etapa "Iniciando FREGONATOR" -Progreso 0 -Log "Sistema iniciado"

# =============================================================================
# SPLASH SCREEN - NALA
# =============================================================================
function Show-NalaSplash {
    Clear-Host
    $cocoColors = @("DarkYellow","Yellow","Magenta","Red","DarkMagenta","Blue","Cyan","Green")
    $nalaArt = @(
        "",
        "",
        "                   ......                  .............  ",
        "                .....;;...                ................  ",
        "             .......;;;;;/mmmmmmmmmmmmmm\/..................  ",
        "           ........;;;mmmmmmmmmmmmmmmmmmm.....................  ",
        "         .........;;m/;;;;\mmmmmm/;;;;;\m......................  ",
        "      ..........;;;m;;mmmm;;mmmm;;mmmmm;;m......................  ",
        "    ..........;;;;;mmmnnnmmmmmmmmmmnnnmmmm\......................  ",
        "    .........  ;;;;;n/#####\nmmmmn/#####\nmm\...................  ",
        "    .......     ;;;;n##...##nmmmmn##...##nmmmm\.................  ",
        "    ....        ;;;n#..o.|nmmmmn#..o..#nmmmmm,l.............  ",
        "     ..          mmmn\.../nmmmmmmn\.../nmmmm,m,lll.......  ",
        "              /mmmmmmmmmmmmmmmmmmmmmmmmmmm,mmmm,llll..  ",
        "          /mmmmmmmmmmmmmmmmmmmmmmm\nmmmn/mmmmmmm,lll/  ",
        "       /mmmmm/..........\mmmmmmmmmmnnmnnmmmmmmmmm,ll  ",
        "      mmmmmm|..o....o..|mmmmmmmmmmmmmmmmmmmmmmmm,ll  ",
        "      \mmmmmmm\......./mmmmmmmmmmmmmmmmmmmmmmmmm,llo  ",
        "        \mmmmmmm\.../mmmmmmmmmmmmmmmmmmmmmmmmmm,lloo  ",
        "          \mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm,ll/oooo  ",
        "             \mmmmmmmmmmll..;;;.;;;;;;/mmm,lll/oooooo\  ",
        "                       ll..;;;.;;;;;;/llllll/ooooooooo\  ",
        "                       ll.;;;.;;;;;/.llll/oooooooooooo\  ",
        "                       ll;;;.;;;;;;..ll/ooooooooooooooo\  ",
        "                       \;;;;.;;;;;..ll/oooooooooooooooo\  ",
        "                     ;;;;;;;;;;;;..ll|oooooooooooooooo  ",
        "                    ;;;;;;.;;;;;;.ll/ooooooooooooooooooo\  ",
        "                    ;;;;;.;;;;;;;ll/ooooooooooooo.....oooo  ",
        "                     \;;;.;;;;;;/oooooooooooo.....oooooooo\  ",
        "                      \;;;.;;;;/ooooooooo.....ooooooooooooo  ",
        "                        \;;;;/ooooooo.....oooooooooooooooo\  ",
        "                        |o\;/oooo.....ooooooooooooooooooooo\  ",
        "                        oooooo....ooooooooooooooooooooooooo\  ",
        "                       oooo....oooooooooooooooooooooooooooo\  ",
        "                      ___.ooooooooooooooooooooooooooooooooooo\  ",
        "                     /XXX\oooooooooooooooooooooooooooooooooooo\ ",
        "                     |XXX|ooooo.ooooooooooooooooooooooooooooooo\  ",
        "                   /oo\X/oooo..ooooooooooooooooooooooooooooooooo\  ",
        "                 /ooooooo..ooooo..oooooooooooooooooooooooooooooo\ ",
        "               /oooooooooooooooooooooooooooooooooooooooooooooooooo\ ",
        "",
        "                                    NALA  /  Annie  /  Todos  /  ...",
        ""
    )
    $colorIndex = 0
    foreach ($line in $nalaArt) {
        Write-Host $line -ForegroundColor $cocoColors[$colorIndex % $cocoColors.Count]
        $colorIndex++
        Start-Sleep -Milliseconds 30
    }
    # Woof woof! Ladrido de Nala
    $barkPath = "$PSScriptRoot\sounds\bark.wav"
    if (Test-Path $barkPath) {
        try {
            $bark = New-Object System.Media.SoundPlayer $barkPath
            $bark.PlaySync()
            Start-Sleep -Milliseconds 100
            $bark.PlaySync()
        } catch {}
    }
    Write-Host ""
    Write-Host "                              Cargando FREGONATOR..." -ForegroundColor Cyan
    Write-Host ""
    Start-Sleep -Milliseconds 400
}

# Fondo oscuro - 100% standalone, sin dependencias
function Set-FondoOscuro {
    $Host.UI.RawUI.BackgroundColor = 'Black'
    $Host.UI.RawUI.ForegroundColor = 'White'
    Clear-Host
}
Set-FondoOscuro

# =============================================================================
# CONFIGURACION
# =============================================================================

$script:CONFIG = @{
    Version = "v4.0"
    LogPath = "$env:USERPROFILE\Documents\ARCAMIA-MEMMEM\Logs\FREGONATOR"
    HistorialPath = "$env:USERPROFILE\Documents\ARCAMIA-MEMMEM\Logs\FREGONATOR\historial.json"
    Idioma = "es"  # es, gl, en
    CarpetasLimpieza = @(
        @{ Path = "$env:TEMP"; Name = "Temp Usuario" }
        @{ Path = "$env:windir\Temp"; Name = "Temp Windows" }
        @{ Path = "$env:LOCALAPPDATA\Temp"; Name = "Local Temp" }
        @{ Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"; Name = "Cache Chrome" }
        @{ Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"; Name = "Cache Edge" }
        @{ Path = "$env:APPDATA\Mozilla\Firefox\Profiles"; Name = "Cache Firefox" }
        @{ Path = "$env:windir\SoftwareDistribution\Download"; Name = "Windows Update Cache" }
        @{ Path = "$env:windir\Prefetch"; Name = "Prefetch" }
    )
    Bloatware = @(
        # Juegos preinstalados
        "*CandyCrush*", "*FarmVille*", "*BubbleWitch*", "*Disney*"
        "*Microsoft.MicrosoftSolitaireCollection*"
        # Apps Microsoft innecesarias
        "*Microsoft.BingWeather*", "*Microsoft.BingNews*"
        "*Microsoft.Xbox*", "*Microsoft.YourPhone*"
        # NOTA: Spotify, Netflix, TikTok, Facebook NO se eliminan
        # Son apps legitimas que el usuario puede querer mantener
    )
}

# Crear carpeta de logs si no existe
if (-not (Test-Path $script:CONFIG.LogPath)) {
    New-Item -Path $script:CONFIG.LogPath -ItemType Directory -Force | Out-Null
}

$script:CurrentLogFile = $null
$script:Stats = @{ StartTime = $null; TotalLiberado = 0; BytesAntes = 0; BytesDespues = 0 }

# =============================================================================
# SISTEMA MULTI-IDIOMA (es/gl/en)
# =============================================================================

$script:IDIOMAS = @{
    es = @{
        # Menu principal
        titulo = "FREGONATOR - OPTIMIZADOR DE PC"
        limpiezaRapida = "LIMPIEZA RAPIDA"
        limpiezaCompleta = "LIMPIEZA COMPLETA"
        menuTerminal = "MENU TERMINAL"
        rapida = "ONE-CLICK RAPIDA"
        avanzada = "ONE-CLICK AVANZADA"
        profunda = "PRE-CLONADISCOS"
        salir = "Salir"
        volver = "Volver"
        rendimiento = "Rendimiento"
        idioma = "Idioma"
        programar = "Programar limpieza"
        historial = "Historial"
        opcion = "Opcion"
        # Menu descripciones
        descRapida = "Temporales, cache, papelera, RAM (8 tareas)"
        descCompleta = "Todo + bloatware, telemetria, optimizacion (13 tareas)"
        descTerminal = "Modo avanzado con todas las opciones"
        tareasParalelas = "tareas en paralelo"
        segundos = "segundos"
        alFinalPuedes = "Al final puedes elegir"
        reparar = "reparar"
        # Tareas nombres
        liberarRAM = "Liberar RAM"
        limpiarTemp = "Limpiar temporales"
        vaciarPapelera = "Vaciar papelera"
        cacheDNS = "Cache DNS"
        optimizarDiscos = "Optimizar discos"
        altoRendimiento = "Alto rendimiento"
        actualizarApps = "Actualizar apps"
        windowsUpdate = "Windows Update"
        eliminarBloatware = "Eliminar bloatware"
        telemetriaOff = "Telemetria OFF"
        registroMRU = "Registro MRU"
        matarProcesos = "Matar procesos"
        efectosVisuales = "Efectos visuales"
        # Tareas en progreso
        liberandoRAM = "Liberando RAM"
        limpiandoTemp = "Limpiando temporales"
        vaciandoPapelera = "Vaciando papelera"
        limpiandoDNS = "Limpiando cache DNS"
        optimizandoDiscos = "Optimizando discos"
        configurandoEnergia = "Configurando energia"
        actualizandoApps = "Actualizando apps"
        verificandoUpdates = "Verificando Windows Update"
        eliminandoBloatware = "Eliminando bloatware"
        limpiandoRegistro = "Limpiando registro MRU"
        matandoProcesos = "Matando procesos"
        desactivandoTelemetria = "Desactivando telemetria"
        optimizandoEfectos = "Optimizando efectos"
        # Estados
        pendiente = "Pendiente"
        ejecutando = "Ejecutando"
        completado = "Completado"
        error = "Error"
        advertencia = "Advertencia"
        ok = "OK"
        abortado = "ABORTADO"
        # Mensajes finales
        limpiezaFinalizada = "Limpieza finalizada"
        espacioLiberado = "Espacio liberado"
        tiempoTotal = "Tiempo total"
        tareas = "tareas"
        tareasCompletadas = "tareas completadas"
        presionaParaVolver = "Pulsa cualquier tecla para volver"
        cerrandoEn = "Cerrando en"
        # Barras paralelas
        ejecucionParalela = "EJECUCION PARALELA"
        tareasBasicasAvanzadas = "tareas (basicas + avanzadas)"
        abortar = "Abortar"
        abortadoPorUsuario = "ABORTADO por el usuario"
        global = "GLOBAL"
        # Advertencias
        notaPCsDesactualizados = "En PCs desactualizados, winget y Windows Update pueden tardar varios minutos. Esto es NORMAL."
        pulsaESC = "Pulsa [ESC] en cualquier momento para abortar"
        creandoPuntoRestauracion = "Creando punto de restauracion (por seguridad)"
        puntoCreado = "Punto de restauracion creado"
        puntoExiste = "Ya existe un punto reciente (continua)"
        # Winget
        wingetNoInstalado = "winget no esta instalado"
        instalandoWinget = "Instalando winget..."
        # Programar
        programarTitulo = "PROGRAMAR LIMPIEZA AUTOMATICA"
        programarDescripcion = "Ejecutar FREGONATOR cada noche a las"
        programarCreada = "Tarea programada creada"
        programarEliminada = "Tarea programada eliminada"
        otraHora = "Otra hora (escribir)"
        eliminarTarea = "Eliminar tarea programada"
        formatoInvalido = "Formato invalido. Usa HH:MM (ej: 06:30)"
        introduceHora = "Introduce hora (HH:MM)"
        noHabiaTarea = "No habia tarea programada"
        # Historial
        historialTitulo = "HISTORIAL DE LIMPIEZAS"
        historialVacio = "No hay limpiezas anteriores"
        fecha = "FECHA"
        modo = "MODO"
        mb = "MB"
        tiempo = "TIEMPO"
        # Notificacion
        notificacionTitulo = "FREGONATOR"
        notificacionListo = "Limpieza completada"
        # Comparativa
        comparativaAntes = "Antes"
        comparativaDespues = "Despues"
        comparativaAhorro = "Ahorro"
        # Menu inferior
        desinstalarApps = "Desinstalar apps"
        appsArranque = "Apps arranque"
        logs = "Logs"
        drivers = "Drivers"
        noHayLogs = "No hay logs todavia"
        mover = "Mover"
        ejecutar = "Ejecutar"
        atajo = "Atajo"
        # Driver Updater
        driverTitulo = "ACTUALIZADOR DE DRIVERS"
        driverAnalizando = "Analizando drivers instalados..."
        driverDispositivo = "DISPOSITIVO"
        driverFecha = "FECHA"
        driverFabricante = "FABRICANTE"
        driverAntiguo = "Amarillo = Driver antiguo (>2 anos)"
        driverMostrando = "Mostrando 15 mas recientes"
        driverBuscar = "Buscar actualizaciones (Windows Update)"
        driverAdministrador = "Abrir Administrador de dispositivos"
        driverWindowsUpdate = "Abrir Windows Update"
        driverBuscando = "Buscando actualizaciones de drivers..."
        driverEspera = "Esto puede tardar unos minutos..."
        driverOK = "Busqueda iniciada. Drivers se instalaran automaticamente."
        driverAbriendo = "Abriendo Windows Update para ver progreso..."
        volverAlMenu = "Volver al menu"
        enterParaVolver = "ENTER para volver"
    }
    gl = @{
        # Menu principal
        titulo = "FREGONATOR - OPTIMIZADOR DE PC"
        rapida = "UN CLICK RAPIDA"
        avanzada = "UN CLICK AVANZADA"
        profunda = "PRE-CLONADISCOS"
        salir = "Sair"
        volver = "Volver"
        rendimiento = "Rendemento"
        idioma = "Idioma"
        programar = "Programar limpeza"
        historial = "Historial"
        # Tareas
        liberandoRAM = "Liberando RAM"
        limpiandoTemp = "Limpando temporais"
        vaciandoPapelera = "Baleirando papeleira"
        limpiandoDNS = "Limpando cache DNS"
        optimizandoDiscos = "Optimizando discos"
        configurandoEnergia = "Configurando enerxia"
        actualizandoApps = "Actualizando apps"
        verificandoUpdates = "Verificando Windows Update"
        # Mensajes
        completado = "Completado"
        error = "Erro"
        advertencia = "Aviso"
        limpiezaFinalizada = "Limpeza rematada"
        espacioLiberado = "Espazo liberado"
        tiempoTotal = "Tempo total"
        tareas = "tarefas"
        wingetNoInstalado = "winget non esta instalado"
        instalandoWinget = "Instalando winget..."
        programarTitulo = "PROGRAMAR LIMPEZA AUTOMATICA"
        programarDescripcion = "Executar FREGONATOR cada noite as"
        programarCreada = "Tarefa programada creada"
        programarEliminada = "Tarefa programada eliminada"
        historialTitulo = "HISTORIAL DE LIMPEZAS"
        historialVacio = "Non hai limpezas anteriores"
        notificacionTitulo = "FREGONATOR"
        notificacionListo = "Limpeza completada"
        comparativaAntes = "Antes"
        comparativaDespues = "Despois"
        comparativaAhorro = "Aforro"
    }
    en = @{
        # Main menu
        titulo = "FREGONATOR - PC OPTIMIZER"
        limpiezaRapida = "QUICK CLEANUP"
        limpiezaCompleta = "FULL CLEANUP"
        menuTerminal = "TERMINAL MENU"
        rapida = "ONE-CLICK QUICK"
        avanzada = "ONE-CLICK ADVANCED"
        profunda = "PRE-CLONE DEEP"
        salir = "Exit"
        volver = "Back"
        rendimiento = "Performance"
        idioma = "Language"
        programar = "Schedule cleanup"
        historial = "History"
        opcion = "Option"
        # Menu descriptions
        descRapida = "Temp files, cache, recycle bin, RAM (8 tasks)"
        descCompleta = "All + bloatware, telemetry, optimization (13 tasks)"
        descTerminal = "Advanced mode with all options"
        tareasParalelas = "parallel tasks"
        segundos = "seconds"
        alFinalPuedes = "At the end you can choose"
        reparar = "repair"
        # Task names
        liberarRAM = "Free RAM"
        limpiarTemp = "Clean temp files"
        vaciarPapelera = "Empty recycle bin"
        cacheDNS = "DNS Cache"
        optimizarDiscos = "Optimize disks"
        altoRendimiento = "High performance"
        actualizarApps = "Update apps"
        windowsUpdate = "Windows Update"
        eliminarBloatware = "Remove bloatware"
        telemetriaOff = "Telemetry OFF"
        registroMRU = "Registry MRU"
        matarProcesos = "Kill processes"
        efectosVisuales = "Visual effects"
        # Tasks in progress
        liberandoRAM = "Freeing RAM"
        limpiandoTemp = "Cleaning temp files"
        vaciandoPapelera = "Emptying recycle bin"
        limpiandoDNS = "Flushing DNS cache"
        optimizandoDiscos = "Optimizing disks"
        configurandoEnergia = "Setting power plan"
        actualizandoApps = "Updating apps"
        verificandoUpdates = "Checking Windows Update"
        eliminandoBloatware = "Removing bloatware"
        limpiandoRegistro = "Cleaning registry MRU"
        matandoProcesos = "Killing processes"
        desactivandoTelemetria = "Disabling telemetry"
        optimizandoEfectos = "Optimizing effects"
        # States
        pendiente = "Pending"
        ejecutando = "Running"
        completado = "Completed"
        error = "Error"
        advertencia = "Warning"
        ok = "OK"
        abortado = "ABORTED"
        # Final messages
        limpiezaFinalizada = "Cleanup finished"
        espacioLiberado = "Space freed"
        tiempoTotal = "Total time"
        tareas = "tasks"
        tareasCompletadas = "tasks completed"
        presionaParaVolver = "Press any key to go back"
        cerrandoEn = "Closing in"
        # Parallel bars
        ejecucionParalela = "PARALLEL EXECUTION"
        tareasBasicasAvanzadas = "tasks (basic + advanced)"
        abortar = "Abort"
        abortadoPorUsuario = "ABORTED by user"
        global = "GLOBAL"
        # Warnings
        notaPCsDesactualizados = "On outdated PCs, winget and Windows Update may take several minutes. This is NORMAL."
        pulsaESC = "Press [ESC] at any time to abort"
        creandoPuntoRestauracion = "Creating restore point (for safety)"
        puntoCreado = "Restore point created"
        puntoExiste = "Recent restore point exists (continuing)"
        # Winget
        wingetNoInstalado = "winget is not installed"
        instalandoWinget = "Installing winget..."
        # Schedule
        programarTitulo = "SCHEDULE AUTOMATIC CLEANUP"
        programarDescripcion = "Run FREGONATOR every night at"
        programarCreada = "Scheduled task created"
        programarEliminada = "Scheduled task deleted"
        otraHora = "Other time (type it)"
        eliminarTarea = "Delete scheduled task"
        formatoInvalido = "Invalid format. Use HH:MM (e.g. 06:30)"
        introduceHora = "Enter time (HH:MM)"
        noHabiaTarea = "No scheduled task existed"
        # History
        historialTitulo = "CLEANUP HISTORY"
        historialVacio = "No previous cleanups"
        fecha = "DATE"
        modo = "MODE"
        mb = "MB"
        tiempo = "TIME"
        # Notification
        notificacionTitulo = "FREGONATOR"
        notificacionListo = "Cleanup completed"
        # Comparison
        comparativaAntes = "Before"
        comparativaDespues = "After"
        comparativaAhorro = "Saved"
        # Bottom menu
        desinstalarApps = "Uninstall apps"
        appsArranque = "Startup apps"
        logs = "Logs"
        drivers = "Drivers"
        noHayLogs = "No logs yet"
        mover = "Move"
        ejecutar = "Run"
        atajo = "Shortcut"
        # Driver Updater
        driverTitulo = "DRIVER UPDATER"
        driverAnalizando = "Analyzing installed drivers..."
        driverDispositivo = "DEVICE"
        driverFecha = "DATE"
        driverFabricante = "MANUFACTURER"
        driverAntiguo = "Yellow = Old driver (>2 years)"
        driverMostrando = "Showing 15 most recent"
        driverBuscar = "Search for updates (Windows Update)"
        driverAdministrador = "Open Device Manager"
        driverWindowsUpdate = "Open Windows Update"
        driverBuscando = "Searching for driver updates..."
        driverEspera = "This may take a few minutes..."
        driverOK = "Search started. Drivers will install automatically."
        driverAbriendo = "Opening Windows Update to see progress..."
        volverAlMenu = "Back to menu"
        enterParaVolver = "ENTER to go back"
    }
}

# Funcion para obtener traduccion
function T {
    param([string]$Key)
    $idioma = $script:CONFIG.Idioma
    if ($script:IDIOMAS[$idioma] -and $script:IDIOMAS[$idioma][$Key]) {
        return $script:IDIOMAS[$idioma][$Key]
    }
    # Fallback a español
    if ($script:IDIOMAS["es"][$Key]) {
        return $script:IDIOMAS["es"][$Key]
    }
    return $Key
}

# Detectar idioma del sistema (ES/EN)
function Get-SystemLanguage {
    $culture = (Get-Culture).Name
    switch -Wildcard ($culture) {
        "en*" { return "en" }
        default { return "es" }  # ES por defecto (incluye GL, ES, etc.)
    }
}

# Inicializar idioma desde sistema
$script:CONFIG.Idioma = Get-SystemLanguage

# =============================================================================
# VERIFICAR WINGET
# =============================================================================

function Test-WingetInstalled {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Install-WingetIfNeeded {
    if (-not (Test-WingetInstalled)) {
        Write-Host "    [!] $(T 'wingetNoInstalado')" -ForegroundColor Yellow
        Write-Host "    $(T 'instalandoWinget')" -ForegroundColor Cyan
        try {
            # Intentar instalar via Microsoft Store
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
            return $true
        } catch {
            Write-Host "    [!] No se pudo instalar winget automaticamente" -ForegroundColor Red
            Write-Host "    Descarga manual: https://aka.ms/getwinget" -ForegroundColor Gray
            return $false
        }
    }
    return $true
}

# =============================================================================
# HISTORIAL DE LIMPIEZAS
# =============================================================================

function Get-LimpiezaHistorial {
    if (Test-Path $script:CONFIG.HistorialPath) {
        try {
            return Get-Content $script:CONFIG.HistorialPath -Raw | ConvertFrom-Json
        } catch {
            return @()
        }
    }
    return @()
}

function Add-LimpiezaHistorial {
    param(
        [string]$Modo,
        [long]$BytesLiberados,
        [int]$Tareas,
        [timespan]$Duracion
    )
    $historial = @(Get-LimpiezaHistorial)
    $entrada = @{
        Fecha = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Modo = $Modo
        BytesLiberados = $BytesLiberados
        MBLiberados = [math]::Round($BytesLiberados / 1MB, 1)
        Tareas = $Tareas
        DuracionSegundos = [int]$Duracion.TotalSeconds
    }
    $historial = @($entrada) + $historial
    # Mantener solo ultimas 50 limpiezas
    if ($historial.Count -gt 50) {
        $historial = $historial[0..49]
    }
    $historial | ConvertTo-Json -Depth 3 | Out-File $script:CONFIG.HistorialPath -Encoding UTF8
}

function Show-LimpiezaHistorial {
    $historial = Get-LimpiezaHistorial
    Write-Host ""
    Write-Host "    ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║                     $(T 'historialTitulo')                          ║" -ForegroundColor Cyan
    Write-Host "    ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan

    if ($historial.Count -eq 0) {
        Write-Host "    ║  $(T 'historialVacio')                                            ║" -ForegroundColor Gray
    } else {
        Write-Host "    ║  FECHA                MODO              MB       TIEMPO        ║" -ForegroundColor White
        Write-Host "    ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor DarkGray
        $count = 0
        foreach ($h in $historial) {
            if ($count -ge 10) { break }
            $fecha = $h.Fecha.Substring(0, 16)
            $modo = $h.Modo.PadRight(16).Substring(0, 16)
            $mb = "$($h.MBLiberados) MB".PadLeft(8)
            $tiempo = "$($h.DuracionSegundos)s".PadLeft(6)
            Write-Host "    ║  $fecha  $modo  $mb  $tiempo        ║" -ForegroundColor Gray
            $count++
        }
    }
    Write-Host "    ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Pulsa cualquier tecla para volver..." -ForegroundColor DarkGray
    if ($script:EsConsolaInteractiva) {
        $null = [Console]::ReadKey($true)
    } else {
        Read-Host
    }
}

# =============================================================================
# NOTIFICACION WINDOWS
# =============================================================================

function Show-WindowsNotification {
    param(
        [string]$Titulo = "FREGONATOR",
        [string]$Mensaje = "Limpieza completada"
    )
    try {
        # Usar notificacion nativa de Windows (sin dependencias)
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        $template = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$Titulo</text>
            <text>$Mensaje</text>
        </binding>
    </visual>
</toast>
"@
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($template)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("FREGONATOR").Show($toast)
    } catch {
        # Fallback: no hacer nada si falla (silencioso)
    }
}

# =============================================================================
# PROGRAMAR LIMPIEZA AUTOMATICA
# =============================================================================

function Show-ProgramarLimpieza {
    Write-Host ""
    Write-Host "    ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║                    PROGRAMAR LIMPIEZA AUTOMATICA                  ║" -ForegroundColor Cyan
    Write-Host "    ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "    ║  [1] 03:00                                                        ║" -ForegroundColor White
    Write-Host "    ║  [2] 04:00                                                        ║" -ForegroundColor White
    Write-Host "    ║  [3] 05:00                                                        ║" -ForegroundColor White
    Write-Host "    ║  [4] Otra hora (escribir)                                         ║" -ForegroundColor White
    Write-Host "    ╟───────────────────────────────────────────────────────────────────╢" -ForegroundColor Cyan
    Write-Host "    ║  [X] Eliminar tarea programada                                    ║" -ForegroundColor Gray
    Write-Host "    ║  [V] Volver                                                       ║" -ForegroundColor Gray
    Write-Host "    ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Opcion: " -NoNewline -ForegroundColor Yellow

    $opcion = Read-Host
    switch ($opcion.ToUpper()) {
        "1" { New-FregonatorScheduledTask -Hora "03:00" }
        "2" { New-FregonatorScheduledTask -Hora "04:00" }
        "3" { New-FregonatorScheduledTask -Hora "05:00" }
        "4" {
            Write-Host ""
            Write-Host "    Introduce hora (HH:MM): " -NoNewline -ForegroundColor Yellow
            $horaCustom = Read-Host
            if ($horaCustom -match '^\d{1,2}:\d{2}$') {
                New-FregonatorScheduledTask -Hora $horaCustom
            } else {
                Write-Host "    [!] Formato invalido. Usa HH:MM (ej: 06:30)" -ForegroundColor Red
                Start-Sleep 2
            }
        }
        "X" { Remove-FregonatorScheduledTask }
        "V" { return }
        default { return }
    }
}

function New-FregonatorScheduledTask {
    param([string]$Hora = "03:00")

    $taskName = "FREGONATOR_AutoClean"
    $scriptPath = $PSCommandPath

    try {
        # Eliminar si existe
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

        # Crear nueva tarea
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -Silent"
        $trigger = New-ScheduledTaskTrigger -Daily -At $Hora
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

        Write-Host ""
        Write-Host "    [OK] $(T 'programarCreada'): $Hora" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "    [ERROR] No se pudo crear la tarea: $_" -ForegroundColor Red
    }

    Start-Sleep -Seconds 2
}

function Remove-FregonatorScheduledTask {
    $taskName = "FREGONATOR_AutoClean"
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
        Write-Host ""
        Write-Host "    [OK] $(T 'programarEliminada')" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "    [!] No habia tarea programada" -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 2
}

# =============================================================================
# DRIVER UPDATER - Actualizar drivers via Windows Update
# =============================================================================

function Show-DriverUpdater {
    Clear-Host
    Show-Logo -Subtitulo (T 'driverTitulo')

    Write-Host ""
    $tituloDriver = (T 'driverTitulo').PadLeft(40 + [math]::Floor((T 'driverTitulo').Length / 2)).PadRight(75)
    Write-Host "    ╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║$tituloDriver║" -ForegroundColor Cyan
    Write-Host "    ╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Mostrar drivers instalados
    Write-Host "    [*] $(T 'driverAnalizando')" -ForegroundColor Yellow
    Write-Host ""

    try {
        $drivers = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue |
            Where-Object { $_.DriverDate -and $_.DeviceName } |
            Sort-Object DriverDate -Descending |
            Select-Object -First 15

        if ($drivers) {
            $hdrDev = (T 'driverDispositivo').PadRight(38)
            $hdrFecha = (T 'driverFecha').PadRight(12)
            $hdrFab = (T 'driverFabricante').PadRight(15)
            Write-Host "    ╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
            Write-Host "    ║  $hdrDev $hdrFecha $hdrFab ║" -ForegroundColor DarkCyan
            Write-Host "    ╟───────────────────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan

            foreach ($drv in $drivers) {
                $nombre = if ($drv.DeviceName.Length -gt 38) { $drv.DeviceName.Substring(0,35) + "..." } else { $drv.DeviceName }
                $fecha = if ($drv.DriverDate) { $drv.DriverDate.ToString("yyyy-MM-dd") } else { "N/A" }
                $fabricante = if ($drv.Manufacturer) {
                    if ($drv.Manufacturer.Length -gt 15) { $drv.Manufacturer.Substring(0,12) + "..." } else { $drv.Manufacturer }
                } else { "N/A" }

                # Color segun antiguedad (>2 años = amarillo, >4 años = rojo)
                $diasAntes = ((Get-Date) - $drv.DriverDate).Days
                $color = "Gray"
                if ($diasAntes -gt 1460) { $color = "DarkYellow" }  # >4 años
                elseif ($diasAntes -gt 730) { $color = "Yellow" }   # >2 años

                $linea = "    ║  {0,-38} {1,-12} {2,-15} ║" -f $nombre, $fecha, $fabricante
                Write-Host $linea -ForegroundColor $color
            }
            Write-Host "    ╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
            Write-Host ""
            Write-Host "    $(T 'driverAntiguo')   |   $(T 'driverMostrando')" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "    [!] $(T 'error')" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "    ╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║  [1] $(T 'driverBuscar')                   ║" -ForegroundColor White
    Write-Host "    ║  [2] $(T 'driverAdministrador')                                  ║" -ForegroundColor White
    Write-Host "    ║  [3] $(T 'driverWindowsUpdate')                                                 ║" -ForegroundColor White
    Write-Host "    ╟───────────────────────────────────────────────────────────────────────────╢" -ForegroundColor Cyan
    Write-Host "    ║  [V] $(T 'volver')                                                       ║" -ForegroundColor Gray
    Write-Host "    ╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    $(if ($script:CONFIG.Idioma -eq 'en') {'Option'} else {'Opcion'}): " -NoNewline -ForegroundColor Yellow

    $opcion = Read-Host
    switch ($opcion.ToUpper()) {
        "1" {
            Write-Host ""
            Write-Host "    [*] $(T 'driverBuscando')" -ForegroundColor Yellow
            Write-Host "    [*] $(T 'driverEspera')" -ForegroundColor DarkGray
            Write-Host ""

            try {
                # Forzar busqueda de drivers via Windows Update
                $UpdateSvc = New-Object -ComObject Microsoft.Update.ServiceManager
                $UpdateSvc.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "") | Out-Null

                # Iniciar busqueda
                Start-Process UsoClient.exe -ArgumentList "StartScan" -NoNewWindow -Wait -ErrorAction SilentlyContinue
                Start-Process UsoClient.exe -ArgumentList "StartDownload" -NoNewWindow -ErrorAction SilentlyContinue

                Write-Host "    [OK] $(T 'driverOK')" -ForegroundColor Green
                Write-Host "    [*] $(T 'driverAbriendo')" -ForegroundColor Cyan
                Start-Sleep -Seconds 2
                Start-Process "ms-settings:windowsupdate"
            } catch {
                Write-Host "    [!] $(T 'driverAbriendo')" -ForegroundColor Yellow
                Start-Process "ms-settings:windowsupdate"
            }

            Write-Host ""
            Write-Host "    ENTER $(T 'volver')..." -ForegroundColor DarkGray
            Read-Host
        }
        "2" {
            Start-Process devmgmt.msc
        }
        "3" {
            Start-Process "ms-settings:windowsupdate"
        }
        "V" { return }
        default { return }
    }
}

# =============================================================================
# COMPARATIVA ANTES/DESPUES
# =============================================================================

function Get-DiscoLibre {
    try {
        $disco = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
        if ($disco) { return $disco.FreeSpace }
    } catch {}
    return 0
}

function Show-Comparativa {
    $antes = $script:Stats.BytesAntes
    $despues = $script:Stats.BytesDespues
    $ahorro = $despues - $antes

    if ($antes -gt 0 -and $despues -gt 0) {
        $antesGB = [math]::Round($antes / 1GB, 2)
        $despuesGB = [math]::Round($despues / 1GB, 2)
        $ahorroMB = [math]::Round($ahorro / 1MB, 0)

        # Ancho fijo del cuadro (65 caracteres internos)
        $boxWidth = 65
        $titulo = "ESPACIO EN DISCO C: ($(T 'comparativaAntes')/$(T 'comparativaDespues'))"
        $linea1 = "$(T 'comparativaAntes'):   $antesGB GB libre"
        $linea2 = "$(T 'comparativaDespues'): $despuesGB GB libre"
        $linea3 = "$(T 'comparativaAhorro'):  +$ahorroMB MB"

        Write-Host ""
        Write-Host "    ┌$('─' * $boxWidth)┐" -ForegroundColor Cyan
        Write-Host "    │$($titulo.PadLeft(($boxWidth + $titulo.Length) / 2).PadRight($boxWidth))│" -ForegroundColor Cyan
        Write-Host "    ├$('─' * $boxWidth)┤" -ForegroundColor DarkGray
        Write-Host "    │  $($linea1.PadRight($boxWidth - 2))│" -ForegroundColor Gray
        Write-Host "    │  $($linea2.PadRight($boxWidth - 2))│" -ForegroundColor White
        Write-Host "    │  $($linea3.PadRight($boxWidth - 2))│" -ForegroundColor Green
        Write-Host "    └$('─' * $boxWidth)┘" -ForegroundColor Cyan
    }
}

# =============================================================================
# LOGGING
# =============================================================================

function Start-FregonatorLog {
    param([string]$Operation)
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $script:CurrentLogFile = Join-Path $script:CONFIG.LogPath "FREGONATOR_${timestamp}.log"

    $header = @"
================================================================================
FREGONATOR - LOG DE OPERACION
================================================================================
Fecha:       $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Operacion:   $Operation
Usuario:     $env:USERNAME
Equipo:      $env:COMPUTERNAME
================================================================================

"@
    $header | Out-File -FilePath $script:CurrentLogFile -Encoding UTF8
}

function Write-FregonatorLog {
    param([string]$Message)
    if ($script:CurrentLogFile) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        "[$timestamp] $Message" | Out-File -FilePath $script:CurrentLogFile -Append -Encoding UTF8
    }
}

# =============================================================================
# SISTEMA DE REPORTES - Estadisticas por tarea
# =============================================================================

$script:TaskResults = @()

function Add-TaskResult {
    param(
        [string]$Nombre,
        [string]$Estado = "OK",
        [long]$BytesLiberados = 0,
        [string]$Detalle = ""
    )
    $script:TaskResults += @{
        Nombre = $Nombre
        Estado = $Estado
        BytesLiberados = $BytesLiberados
        Detalle = $Detalle
        Timestamp = Get-Date
    }
    Write-FregonatorLog "$Nombre - $Estado $(if($BytesLiberados -gt 0){"- $([math]::Round($BytesLiberados/1MB,1)) MB"})"
}

function Show-FregonatorResumen {
    $duracion = (Get-Date) - $script:Stats.StartTime
    $totalBytes = ($script:TaskResults | ForEach-Object { $_.BytesLiberados } | Measure-Object -Sum).Sum
    $totalMB = [math]::Round($totalBytes / 1MB, 0)
    $totalGB = [math]::Round($totalBytes / 1GB, 2)
    $tareasOK = ($script:TaskResults | Where-Object { $_.Estado -eq "OK" }).Count
    $tareasTotal = $script:TaskResults.Count
    $fecha = Get-Date -Format "dd-MM-yyyy HH:mm"

    Write-Host ""
    # Limpiar lineas residuales de tiempo (150 espacios para cubrir todo el ancho)
    $limpiar = " " * 150
    Write-Host $limpiar
    Write-Host $limpiar
    Write-Host $limpiar
    Write-Host $limpiar
    Write-Host $limpiar
    Write-Host $limpiar
    Write-Host "    ┌─────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "                            FREGONATOR - RESUMEN                               " -ForegroundColor Cyan
    Write-Host "    ├─────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "      TAREA                              ESTADO    LIBERADO                    " -ForegroundColor White
    Write-Host "    ├─────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkGray

    foreach ($task in $script:TaskResults) {
        $nombre = $task.Nombre.PadRight(36)
        $estado = if ($task.Estado -eq "OK") { "OK" } else { "SKIP" }
        $estadoColor = if ($task.Estado -eq "OK") { "Cyan" } else { "Yellow" }
        $liberado = if ($task.BytesLiberados -gt 0) { "$([math]::Round($task.BytesLiberados/1MB,1)) MB" } else { "-" }

        Write-Host "      $nombre" -NoNewline -ForegroundColor White
        Write-Host "$($estado.PadRight(10))" -NoNewline -ForegroundColor $estadoColor
        Write-Host "$liberado" -ForegroundColor Cyan
    }

    Write-Host "    ├─────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan

    $durTxt = if ($duracion.TotalMinutes -ge 1) {
        "$([math]::Floor($duracion.TotalMinutes))m $([math]::Round($duracion.Seconds))s"
    } else {
        "$([math]::Round($duracion.TotalSeconds))s"
    }

    $liberadoTxt = if ($totalGB -ge 1) { "Liberado: $totalGB GB" } else { "Liberado: $totalMB MB" }
    Write-Host "      TOTAL: $tareasOK/$tareasTotal tareas | Tiempo: $durTxt | $liberadoTxt" -ForegroundColor Cyan
    Write-Host "      $fecha" -ForegroundColor DarkGray
    Write-Host "    └─────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
}

function Export-FregonatorHTML {
    param([string]$OutputPath = "")

    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $OutputPath = Join-Path $script:CONFIG.LogPath "FREGONATOR_$timestamp.html"
    }

    $duracion = (Get-Date) - $script:Stats.StartTime
    $totalBytes = ($script:TaskResults | ForEach-Object { $_.BytesLiberados } | Measure-Object -Sum).Sum
    $totalMB = [math]::Round($totalBytes / 1MB, 0)
    $totalGB = [math]::Round($totalBytes / 1GB, 2)
    $tareasOK = ($script:TaskResults | Where-Object { $_.Estado -eq "OK" }).Count
    $tareasTotal = $script:TaskResults.Count
    $fecha = Get-Date -Format "dddd, d 'de' MMMM 'de' yyyy HH:mm"
    $durTxt = if ($duracion.TotalMinutes -ge 1) {
        "$([math]::Floor($duracion.TotalMinutes)) min $([math]::Round($duracion.Seconds)) seg"
    } else {
        "$([math]::Round($duracion.TotalSeconds)) segundos"
    }
    $liberadoTxt = if ($totalGB -ge 1) { "$totalGB GB" } else { "$totalMB MB" }

    # Generar filas de la tabla
    $tableRows = ""
    foreach ($task in $script:TaskResults) {
        $estadoIcon = if ($task.Estado -eq "OK") { "&#10004;" } else { "&#8211;" }
        $estadoColor = if ($task.Estado -eq "OK") { "#2E7D32" } else { "#F57C00" }
        $liberado = if ($task.BytesLiberados -gt 0) {
            "$([math]::Round($task.BytesLiberados/1MB,1)) MB"
        } else {
            "-"
        }
        $tableRows += @"

<tr>
    <td class="Regular">$($task.Nombre)</td>
    <td class="Secondary" style="color: $estadoColor; font-weight: 600;">$estadoIcon $($task.Estado)</td>
    <td class="Secondary">$liberado</td>
</tr>
"@
    }

    $html = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>FREGONATOR - Informe de Optimizacion</title>
    <style>
        body {
            font-family: "Segoe UI", sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #ffffff;
            margin: 0;
            padding: 40px 60px;
            min-height: 100vh;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255,255,255,0.05);
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        div.header {
            font-family: "Segoe UI Light", sans-serif;
            font-size: 28pt;
            color: #00BCD4;
            padding-bottom: 10px;
            border-bottom: 2px solid #00BCD4;
            margin-bottom: 30px;
        }
        .subtitle {
            font-size: 14pt;
            color: #888;
            margin-top: -20px;
            margin-bottom: 30px;
        }
        .stats-box {
            display: flex;
            justify-content: space-between;
            background: rgba(0,188,212,0.1);
            border: 1px solid #00BCD4;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 30px;
        }
        .stat-item {
            text-align: center;
        }
        .stat-value {
            font-size: 24pt;
            font-weight: 600;
            color: #00BCD4;
        }
        .stat-label {
            font-size: 10pt;
            color: #888;
            text-transform: uppercase;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        table tr.Header td {
            font-family: "Segoe UI Semibold", sans-serif;
            font-size: 11pt;
            color: #00BCD4;
            padding: 12px 8px;
            border-bottom: 2px solid #00BCD4;
        }
        table tr td.Regular {
            padding: 12px 8px;
            font-family: "Segoe UI", sans-serif;
            font-size: 11pt;
            color: #ffffff;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        table tr td.Secondary {
            padding: 12px 8px;
            font-family: "Segoe UI", sans-serif;
            font-size: 11pt;
            color: #888;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        div.Copyright {
            padding-top: 40px;
            font-family: "Segoe UI", sans-serif;
            font-size: 10pt;
            color: #555;
            text-align: center;
        }
        .branding {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 10px;
            padding-top: 20px;
            border-top: 1px solid rgba(255,255,255,0.1);
        }
        .branding a {
            color: #00BCD4;
            text-decoration: none;
        }
        .logo-text {
            font-size: 10pt;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">FREGONATOR - Informe de Optimizacion</div>
        <div class="subtitle">$env:COMPUTERNAME - $env:USERNAME</div>

        <div class="stats-box">
            <div class="stat-item">
                <div class="stat-value">$tareasOK/$tareasTotal</div>
                <div class="stat-label">Tareas completadas</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">$liberadoTxt</div>
                <div class="stat-label">Espacio liberado</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">$durTxt</div>
                <div class="stat-label">Duracion</div>
            </div>
        </div>

        <table>
            <tr class="Header">
                <td width="55%">Tarea</td>
                <td width="20%">Estado</td>
                <td width="25%">Liberado</td>
            </tr>
            <tbody>$tableRows
            </tbody>
        </table>

        <div class="Copyright">
            <div>$fecha</div>
            <div class="branding">
                <span class="logo-text">FREGONATOR v4.0 | ARCAMIA-MEMMEM</span>
                <span>
                    <a href="https://www.fregonator.com">fregonator.com</a> |
                    <a href="https://www.costa-da-morte.com">costa-da-morte.com</a>
                </span>
            </div>
        </div>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    return $OutputPath
}

function Complete-FregonatorLog {
    if (-not $script:CurrentLogFile) { return }

    $duracion = (Get-Date) - $script:Stats.StartTime
    $totalBytes = ($script:TaskResults | ForEach-Object { $_.BytesLiberados } | Measure-Object -Sum).Sum
    $totalMB = [math]::Round($totalBytes / 1MB, 0)
    $tareasOK = ($script:TaskResults | Where-Object { $_.Estado -eq "OK" }).Count
    $tareasTotal = $script:TaskResults.Count

    $footer = @"

================================================================================
RESUMEN FINAL
================================================================================
Tareas:     $tareasOK/$tareasTotal completadas
Liberado:   $totalMB MB
Duracion:   $([math]::Round($duracion.TotalSeconds, 0)) segundos
Finalizado: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
================================================================================
"@
    $footer | Out-File -FilePath $script:CurrentLogFile -Append -Encoding UTF8
}

# =============================================================================
# UI - SPLASH Y LOGO
# =============================================================================

function Show-FregonatorSplash {
    # Splash de bienvenida con escoba animada y colores arcoiris
    Clear-Host

    # Colores arcoiris (calidos -> frios)
    $rainbowColors = @(
        "DarkYellow",   # Naranja
        "Yellow",       # Amarillo
        "Green",        # Verde
        "Cyan",         # Cyan
        "Blue",         # Azul
        "Magenta",      # Magenta
        "Red"           # Rojo
    )

    # ASCII art de escoba/fregona con Nala
    $splashArt = @(
        "",
        "                              .--.",
        "                             /    \",
        "                            |  ()  |",
        "                             \    /",
        "                              |  |",
        "                              |  |",
        "                              |  |",
        "                         _____|  |_____",
        "                        /              \",
        "                       |   FREGONATOR   |",
        "                       |     v4.0     |",
        "                        \______________/",
        "                         |||||||||||||||",
        "                         |||||||||||||||",
        "                         |||||||||||||||",
        "                          |||||||||||||",
        "                           |||||||||||",
        "                            |||||||||",
        "",
        "                    Limpiando tu PC con estilo...",
        ""
    )

    # Mostrar con barrido de colores
    $colorIndex = 0
    foreach ($line in $splashArt) {
        $color = $rainbowColors[$colorIndex % $rainbowColors.Count]
        Write-Host $line -ForegroundColor $color
        $colorIndex++
        Start-Sleep -Milliseconds 40
    }

    # Sonido de bienvenida
    try {
        $chordPlayer = New-Object System.Media.SoundPlayer "C:\Windows\Media\chord.wav"
        $chordPlayer.PlaySync()
    } catch {}

    Start-Sleep -Milliseconds 250

    # Box de creditos
    Write-Host "        ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
    Write-Host "        ║       " -NoNewline -ForegroundColor DarkGray
    Write-Host "Desarrollado con " -NoNewline -ForegroundColor Gray
    Write-Host "CLAUDE CODE" -NoNewline -ForegroundColor Cyan
    Write-Host " (" -NoNewline -ForegroundColor Gray
    Write-Host "ANTHROPIC" -NoNewline -ForegroundColor Cyan
    Write-Host ")" -NoNewline -ForegroundColor Gray
    Write-Host "            ║" -ForegroundColor DarkGray
    Write-Host "        ╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor DarkGray
    Write-Host "        ║     " -NoNewline -ForegroundColor DarkGray
    Write-Host "COSTA DA MORTE" -NoNewline -ForegroundColor Cyan
    Write-Host " # " -NoNewline -ForegroundColor DarkGray
    Write-Host "DEATH COAST" -NoNewline -ForegroundColor Cyan
    Write-Host "     " -NoNewline -ForegroundColor DarkGray
    Write-Host "www.costa-da-morte.com" -NoNewline -ForegroundColor Cyan
    Write-Host "     ║" -ForegroundColor DarkGray
    Write-Host "        ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray

    Start-Sleep -Milliseconds 500
}

function Show-Logo {
    param([string]$Subtitulo = "")

    Clear-Host
    Write-Host ""
    Write-Host "    ███████╗██████╗ ███████╗ ██████╗  ██████╗ ███╗   ██╗ █████╗ ████████╗ ██████╗ ██████╗ " -ForegroundColor Cyan
    Write-Host "    ██╔════╝██╔══██╗██╔════╝██╔════╝ ██╔═══██╗████╗  ██║██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗" -ForegroundColor Cyan
    Write-Host "    █████╗  ██████╔╝█████╗  ██║  ███╗██║   ██║██╔██╗ ██║███████║   ██║   ██║   ██║██████╔╝" -ForegroundColor Cyan
    Write-Host "    ██╔══╝  ██╔══██╗██╔══╝  ██║   ██║██║   ██║██║╚██╗██║██╔══██║   ██║   ██║   ██║██╔══██╗" -ForegroundColor Cyan
    Write-Host "    ██║     ██║  ██║███████╗╚██████╔╝╚██████╔╝██║ ╚████║██║  ██║   ██║   ╚██████╔╝██║  ██║" -ForegroundColor Cyan
    Write-Host "    ╚═╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host "    SIMPLE · FUNCIONAL                                                              ARCAMIA-MEMMEM" -ForegroundColor DarkGray
    Write-Host "    Clona tu DISCO con UN CLICK                                                www.clonadiscos.com" -ForegroundColor DarkGray
    Write-Host "    Optimiza tu PC con UN CLICK                                                 www.fregonator.com" -ForegroundColor DarkGray
    Write-Host "    " -NoNewline
    Write-Host "COSTA DA MORTE" -NoNewline -ForegroundColor Cyan
    Write-Host " # " -NoNewline -ForegroundColor DarkGray
    Write-Host "DEATH COAST" -NoNewline -ForegroundColor Cyan
    Write-Host "                                            www.costa-da-morte.com" -ForegroundColor Cyan
    Write-Host ""

    if ($Subtitulo) {
        Write-Host "    $Subtitulo" -ForegroundColor Yellow
        Write-Host ""
    }
}

# =============================================================================
# INFO DEL PC - Caracteristicas basicas del sistema
# =============================================================================

$script:CachedPCInfo = $null

function Get-PCInfo {
    <#
    .SYNOPSIS
        Obtiene info basica del PC de forma rapida (con cache)
    #>
    # Usar cache si existe
    if ($script:CachedPCInfo) { return $script:CachedPCInfo }

    $info = @{}

    try {
        # CPU
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpu) {
            $cpuName = $cpu.Name -replace '\s+', ' ' -replace '\(R\)|\(TM\)|CPU|@.*', ''
            $info.CPU = "$($cpuName.Trim()) ($($cpu.NumberOfCores)C/$($cpu.NumberOfLogicalProcessors)T)"
        }

        # RAM
        $ram = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $ramFree = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($ram -and $ramFree) {
            $totalGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 0)
            $freeGB = [math]::Round($ramFree.FreePhysicalMemory / 1MB, 1)
            $info.RAM = "$totalGB GB ($freeGB GB libre)"
        }

        # Disco C:
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
        if ($disk) {
            $totalGB = [math]::Round($disk.Size / 1GB, 0)
            $freeGB = [math]::Round($disk.FreeSpace / 1GB, 0)
            $pct = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 0)
            $info.Disco = "C: $freeGB GB libres de $totalGB GB ($pct%)"
        }

        # GPU
        $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($gpu) {
            $gpuName = $gpu.Name -replace '\s+', ' '
            if ($gpuName.Length -gt 40) { $gpuName = $gpuName.Substring(0, 37) + "..." }
            $info.GPU = $gpuName
        }

        # Windows
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $info.Windows = "$($os.Caption -replace 'Microsoft ', '') (Build $($os.BuildNumber))"
        }

        # Nombre PC
        $info.Nombre = $env:COMPUTERNAME

    } catch { }

    # Guardar en cache
    $script:CachedPCInfo = $info
    return $info
}

function Show-PCInfo {
    <#
    .SYNOPSIS
        Muestra info del PC en formato compacto
    #>
    $info = Get-PCInfo

    # Valores seguros
    $pcName = if ($info.Nombre) { [string]$info.Nombre } else { $env:COMPUTERNAME }
    $cpuStr = if ($info.CPU) { [string]$info.CPU } else { "N/A" }
    $ramStr = if ($info.RAM) { [string]$info.RAM } else { "N/A" }
    $gpuStr = if ($info.GPU) { [string]$info.GPU } else { "N/A" }
    $winStr = if ($info.Windows) { [string]$info.Windows } else { "N/A" }
    $discoStr = if ($info.Disco) { [string]($info.Disco -replace 'C: ', '') } else { "N/A" }

    # Truncar
    if ($cpuStr.Length -gt 60) { $cpuStr = $cpuStr.Substring(0, 57) + "..." }
    if ($gpuStr.Length -gt 25) { $gpuStr = $gpuStr.Substring(0, 22) + "..." }
    if ($winStr.Length -gt 25) { $winStr = $winStr.Substring(0, 22) + "..." }
    if ($discoStr.Length -gt 23) { $discoStr = $discoStr.Substring(0, 20) + "..." }

    # Construir lineas (ancho 72 interior, PadRight al final)
    $l1 = ("  PC: " + $pcName).PadRight(72)
    $l2 = ("  CPU: " + $cpuStr).PadRight(72)
    $l3 = ("  RAM: " + $ramStr.PadRight(29) + " GPU: " + $gpuStr).PadRight(72)
    $l4 = ("  WIN: " + $winStr.PadRight(29) + " C:\: " + $discoStr).PadRight(72)

    Write-Host "    +------------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "    |$l1|" -ForegroundColor White
    Write-Host "    |$l2|" -ForegroundColor Gray
    Write-Host "    |$l3|" -ForegroundColor Gray
    Write-Host "    |$l4|" -ForegroundColor Gray
    Write-Host "    +------------------------------------------------------------------------+" -ForegroundColor DarkCyan
}

# =============================================================================
# HEALTH CHECK DEL DISCO - Estado antes de limpiar
# =============================================================================

function Get-SystemHealthCheck {
    <#
    .SYNOPSIS
        Analiza el estado del disco del sistema antes de limpieza profunda
    #>

    $health = @{
        Score = 100
        Status = "SALUDABLE"
        Problemas = @()
        Advertencias = @()
        Info = @{}
    }

    try {
        # Disco del sistema
        $systemDrive = $env:SystemDrive.TrimEnd(':')
        $disk = Get-Disk | Where-Object { (Get-Partition -DiskNumber $_.Number -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -eq $systemDrive }) } | Select-Object -First 1

        if ($disk) {
            $health.Info.DiskNumber = $disk.Number
            $health.Info.DiskModel = $disk.FriendlyName
            $health.Info.DiskSize = "$([math]::Round($disk.Size / 1GB, 0)) GB"

            # Estado operacional
            if ($disk.OperationalStatus -ne "Online") {
                $health.Problemas += "Disco OFFLINE"
                $health.Score -= 50
            }
            if ($disk.HealthStatus -ne "Healthy") {
                $health.Problemas += "Estado: $($disk.HealthStatus)"
                $health.Score -= 30
            }

            # PhysicalDisk para SMART
            $physDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $disk.Number } | Select-Object -First 1
            if ($physDisk) {
                $health.Info.MediaType = $physDisk.MediaType
                $reliability = Get-StorageReliabilityCounter -PhysicalDisk $physDisk -ErrorAction SilentlyContinue

                if ($reliability) {
                    # Temperatura
                    if ($reliability.Temperature) {
                        $health.Info.Temperature = "$($reliability.Temperature) C"
                        if ($reliability.Temperature -gt 50) {
                            $health.Advertencias += "Temperatura alta: $($reliability.Temperature)C"
                            $health.Score -= 10
                        }
                    }

                    # Horas de uso
                    if ($reliability.PowerOnHours) {
                        $dias = [math]::Round($reliability.PowerOnHours / 24)
                        $health.Info.PowerOnDays = "$dias dias"
                        if ($reliability.PowerOnHours -gt 40000) {
                            $health.Advertencias += "Disco veterano: $dias dias encendido"
                            $health.Score -= 5
                        }
                    }

                    # Errores
                    if ($reliability.ReadErrorsTotal -and $reliability.ReadErrorsTotal -gt 0) {
                        $health.Problemas += "Errores de lectura: $($reliability.ReadErrorsTotal)"
                        $health.Score -= 20
                    }
                    if ($reliability.WriteErrorsTotal -and $reliability.WriteErrorsTotal -gt 0) {
                        $health.Problemas += "Errores de escritura: $($reliability.WriteErrorsTotal)"
                        $health.Score -= 20
                    }

                    # Desgaste SSD
                    if ($reliability.Wear -and $reliability.Wear -gt 0) {
                        $health.Info.Wear = "$($reliability.Wear)%"
                        if ($reliability.Wear -gt 80) {
                            $health.Problemas += "SSD muy desgastado: $($reliability.Wear)%"
                            $health.Score -= 30
                        }
                    }
                }
            }
        }

        # Espacio libre en C:
        $vol = Get-Volume -DriveLetter $systemDrive -ErrorAction SilentlyContinue
        if ($vol) {
            $freeGB = [math]::Round($vol.SizeRemaining / 1GB, 1)
            $totalGB = [math]::Round($vol.Size / 1GB, 1)
            $pctFree = [math]::Round(($vol.SizeRemaining / $vol.Size) * 100, 0)
            $health.Info.FreeSpace = "$freeGB GB libres de $totalGB GB - $pctFree%"

            if ($pctFree -lt 10) {
                $health.Problemas += "Disco casi lleno: solo $pctFree% libre"
                $health.Score -= 15
            } elseif ($pctFree -lt 20) {
                $health.Advertencias += "Espacio bajo: $pctFree% libre"
                $health.Score -= 5
            }
        }

    } catch {
        $health.Advertencias += "No se pudo leer info SMART"
    }

    # Determinar estado final
    $health.Score = [math]::Max(0, $health.Score)
    if ($health.Score -ge 90) {
        $health.Status = "SALUDABLE"
    } elseif ($health.Score -ge 70) {
        $health.Status = "ACEPTABLE"
    } else {
        $health.Status = "REVISAR"
    }

    return $health
}

function Show-HealthCheckResult {
    param([hashtable]$Health)

    $scoreColor = if ($Health.Score -ge 90) { "Cyan" } elseif ($Health.Score -ge 70) { "Yellow" } else { "Red" }

    Write-Host ""
    Write-Host "    ╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║                    HEALTH CHECK DEL DISCO                       ║" -ForegroundColor Cyan
    Write-Host "    ╠═════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan

    # Info basica
    if ($Health.Info.DiskModel) {
        Write-Host "    ║  Disco: $($Health.Info.DiskModel.PadRight(55))║" -ForegroundColor White
    }
    if ($Health.Info.DiskSize) {
        Write-Host "    ║  Tamaño: $($Health.Info.DiskSize.PadRight(54))║" -ForegroundColor Gray
    }
    if ($Health.Info.MediaType) {
        Write-Host "    ║  Tipo: $($Health.Info.MediaType.PadRight(56))║" -ForegroundColor Gray
    }
    if ($Health.Info.FreeSpace) {
        Write-Host "    ║  Espacio: $($Health.Info.FreeSpace.PadRight(53))║" -ForegroundColor Gray
    }
    if ($Health.Info.Temperature) {
        Write-Host "    ║  Temperatura: $($Health.Info.Temperature.PadRight(49))║" -ForegroundColor Gray
    }
    if ($Health.Info.PowerOnDays) {
        Write-Host "    ║  Uso: $($Health.Info.PowerOnDays.PadRight(57))║" -ForegroundColor Gray
    }

    Write-Host "    ╠═════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan

    # Score
    $barWidth = 30
    $filled = [math]::Floor(($Health.Score / 100) * $barWidth)
    $bar = ('█' * $filled) + ('░' * ($barWidth - $filled))
    Write-Host "    ║  Puntuacion: [" -NoNewline -ForegroundColor White
    Write-Host $bar -NoNewline -ForegroundColor $scoreColor
    Write-Host "] $($Health.Score)% - $($Health.Status)" -NoNewline -ForegroundColor $scoreColor
    $padding = 65 - 17 - $barWidth - $Health.Score.ToString().Length - $Health.Status.Length
    Write-Host "$(' ' * [math]::Max(0, $padding))║" -ForegroundColor Cyan

    # Problemas
    if ($Health.Problemas.Count -gt 0) {
        Write-Host "    ╠═════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "    ║  PROBLEMAS:                                                     ║" -ForegroundColor Red
        foreach ($p in $Health.Problemas) {
            $txt = "    - $p"
            Write-Host "    ║  $($txt.PadRight(61))║" -ForegroundColor Red
        }
    }

    # Advertencias
    if ($Health.Advertencias.Count -gt 0) {
        Write-Host "    ╠═════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "    ║  ADVERTENCIAS:                                                  ║" -ForegroundColor Yellow
        foreach ($a in $Health.Advertencias) {
            $txt = "    - $a"
            Write-Host "    ║  $($txt.PadRight(61))║" -ForegroundColor Yellow
        }
    }

    Write-Host "    ╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# =============================================================================
# FUNCIONES DE TAREAS
# =============================================================================

function Clear-TempFiles {
    param([switch]$Silent)
    $liberado = 0
    foreach ($target in $script:CONFIG.CarpetasLimpieza) {
        if (Test-Path $target.Path) {
            try {
                $items = Get-ChildItem $target.Path -Recurse -Force -ErrorAction SilentlyContinue
                $size = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                Remove-Item "$($target.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
                $liberado += $size
                if (-not $Silent) {
                    $mb = [math]::Round($size / 1MB, 1)
                    if ($mb -gt 0) {
                        Write-Host "        $($target.Name): $mb MB" -ForegroundColor Gray
                        Write-FregonatorLog "Limpiado $($target.Name): $mb MB"
                    }
                }
            } catch { }
        }
    }
    return $liberado
}

function Clear-RecycleBinSafe {
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-FregonatorLog "Papelera vaciada"
    } catch { }
}

function Clear-RAM {
    try {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Write-FregonatorLog "RAM liberada (GC ejecutado)"
    } catch { }
}

function Clear-DNSCache {
    try {
        ipconfig /flushdns | Out-Null
        Write-FregonatorLog "Cache DNS limpiado"
    } catch { }
}

function Optimize-Disks {
    param([switch]$Silent)
    $ProgressPreference = 'SilentlyContinue'
    try {
        $discos = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }
        foreach ($disco in $discos) {
            $letra = $disco.DriveLetter
            # Detectar si es SSD o HDD
            $diskNumber = (Get-Partition -DriveLetter $letra -ErrorAction SilentlyContinue).DiskNumber
            $mediaType = (Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq $diskNumber }).MediaType

            if (-not $Silent) { Write-Host "        $letra`:..." -ForegroundColor Gray -NoNewline }

            if ($mediaType -eq 'SSD') {
                # SSD: Solo ReTrim (muy rapido, segundos)
                Optimize-Volume -DriveLetter $letra -ReTrim -ErrorAction SilentlyContinue *>&1 | Out-Null
                Write-FregonatorLog "Disco $letra (SSD) - TRIM ejecutado"
            } else {
                # HDD: En modo Silent (UN CLICK) solo analizar, no desfragmentar
                if ($Silent) {
                    # Solo verificar estado, no desfragmentar (tarda mucho)
                    Write-FregonatorLog "Disco $letra (HDD) - Saltado en modo rapido"
                } else {
                    Optimize-Volume -DriveLetter $letra -Defrag -ErrorAction SilentlyContinue *>&1 | Out-Null
                    Write-FregonatorLog "Disco $letra (HDD) - Desfragmentado"
                }
            }
            if (-not $Silent) { Write-Host " OK" -ForegroundColor Cyan }
        }
    } catch { }
}

function Update-Apps {
    Write-FregonatorLog "Iniciando actualizacion de apps (winget)"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            # Lanzar winget en background para no bloquear (max 30 seg espera)
            $job = Start-Job -ScriptBlock {
                winget upgrade --all --accept-source-agreements --accept-package-agreements --silent 2>&1
            }
            # Esperar max 30 segundos
            $completed = Wait-Job -Job $job -Timeout 30
            if ($completed) {
                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
                Write-FregonatorLog "Winget upgrade completado"
            } else {
                # Timeout - dejar corriendo en background
                Write-FregonatorLog "Winget upgrade iniciado (continua en background)"
            }
        } catch { }
    } else {
        Write-FregonatorLog "Winget no disponible"
    }
}

function Update-Windows {
    try {
        Start-Process -FilePath "UsoClient.exe" -ArgumentList "StartScan" -NoNewWindow -ErrorAction SilentlyContinue
        Write-FregonatorLog "Windows Update iniciado (UsoClient StartScan)"
    } catch { }
}

function Set-HighPerformance {
    try {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-FregonatorLog "Plan de energia: Alto Rendimiento"
    } catch { }
}

function Remove-Bloatware {
    $found = @()
    foreach ($pattern in $script:CONFIG.Bloatware) {
        $apps = Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue
        if ($apps) { $found += $apps }
    }
    if ($found.Count -gt 0) {
        foreach ($app in $found) {
            try {
                $app | Remove-AppxPackage -ErrorAction SilentlyContinue
                Write-FregonatorLog "Bloatware eliminado: $($app.Name)"
            } catch { }
        }
    }
    return $found.Count
}

# =============================================================================
# FUNCIONES FUSIONADAS DE OTROS MODULOS
# =============================================================================

function Clear-RegistryMRU {
    <#
    .SYNOPSIS
        Limpia historial MRU del registro (archivos recientes, busquedas, etc.)
        Fusionado de: Limpiar-Registro.ps1
    #>
    $entradasLimpiadas = 0

    # MRU - Most Recently Used
    $mruPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSaveMRU",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedMRU",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    )

    foreach ($path in $mruPaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                $entradasLimpiadas++
            } catch {}
        }
    }

    # Cache de busqueda WordWheelQuery
    $searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
    if (Test-Path $searchPath) {
        try {
            Remove-Item -Path $searchPath -Recurse -Force -ErrorAction SilentlyContinue
            $entradasLimpiadas++
        } catch {}
    }

    # MUICache - rutas de archivos inexistentes
    $muiPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    if (Test-Path $muiPath) {
        $props = Get-ItemProperty $muiPath -ErrorAction SilentlyContinue
        $propsToRemove = @()

        $props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" } | ForEach-Object {
            $filePath = $_.Name -replace "\.FriendlyAppName$", "" -replace "\.ApplicationCompany$", ""
            if ($filePath -match "^[A-Z]:\\" -and -not (Test-Path $filePath)) {
                $propsToRemove += $_.Name
            }
        }

        foreach ($prop in $propsToRemove) {
            Remove-ItemProperty -Path $muiPath -Name $prop -ErrorAction SilentlyContinue
            $entradasLimpiadas++
        }
    }

    Write-FregonatorLog "Registro MRU limpiado: $entradasLimpiadas entradas"
    return $entradasLimpiadas
}

function Stop-UnnecessaryProcesses {
    <#
    .SYNOPSIS
        Cierra procesos innecesarios que consumen RAM
        Fusionado de: Tuning-Total.ps1
    #>
    $procesosACerrar = @(
        'OneDrive',           # Sincronizacion en segundo plano
        'YourPhone',          # Tu telefono
        'GameBar',            # Barra de juegos
        'GrooveMusic',        # Musica Groove
        'SkypeApp',           # Skype
        'Cortana',            # Cortana
        'SearchApp'           # Busqueda
    )

    $cerrados = 0
    $ramLiberada = 0

    foreach ($nombre in $procesosACerrar) {
        $procesos = Get-Process -Name "*$nombre*" -ErrorAction SilentlyContinue
        foreach ($p in $procesos) {
            try {
                $ramLiberada += $p.WorkingSet64
                Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                $cerrados++
            } catch { }
        }
    }

    $ramMB = [math]::Round($ramLiberada / 1MB)
    Write-FregonatorLog "Procesos cerrados: $cerrados ($ramMB MB)"
    return @{ Cerrados = $cerrados; RAMMb = $ramMB }
}

function Optimize-CPUPerformance {
    <#
    .SYNOPSIS
        CPU al 100% y desactiva core parking
        Fusionado de: Tuning-Total.ps1
    #>
    try {
        $activeScheme = (powercfg /getactivescheme) -replace ".*: (\S+).*", '$1'

        # Procesador al 100%
        powercfg /setacvalueindex $activeScheme 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100 2>$null
        powercfg /setacvalueindex $activeScheme 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 2>$null

        # Desactivar core parking
        powercfg /setacvalueindex $activeScheme 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 2>$null

        powercfg /setactive $activeScheme
        Write-FregonatorLog "CPU optimizada: 100%, core parking OFF"
        return $true
    } catch {
        return $false
    }
}

function Disable-TelemetryServices {
    <#
    .SYNOPSIS
        Desactiva servicios de telemetria de Windows
        Fusionado de: Mantenimiento-Total.ps1
    #>
    $serviciosDesactivar = @(
        "DiagTrack",           # Telemetria
        "dmwappushservice",    # WAP Push
        "SysMain"              # Superfetch (en SSD no es necesario)
    )

    $desactivados = 0

    foreach ($servicio in $serviciosDesactivar) {
        try {
            $svc = Get-Service -Name $servicio -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {
                Stop-Service -Name $servicio -Force -ErrorAction SilentlyContinue
                Set-Service -Name $servicio -StartupType Disabled -ErrorAction SilentlyContinue
                Write-FregonatorLog "Servicio desactivado: $servicio"
                $desactivados++
            }
        } catch { }
    }

    return $desactivados
}

function Optimize-VisualEffects {
    <#
    .SYNOPSIS
        Optimiza efectos visuales para mejor rendimiento
        Fusionado de: Mantenimiento-Total.ps1
    #>
    try {
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
        Write-FregonatorLog "Efectos visuales optimizados (modo rendimiento)"
        return $true
    } catch {
        return $false
    }
}

function Clear-ARPCache {
    <#
    .SYNOPSIS
        Limpia cache ARP de red
        Fusionado de: Tuning-Total.ps1
    #>
    try {
        netsh interface ip delete arpcache 2>$null | Out-Null
        Write-FregonatorLog "Cache ARP limpiado"
        return $true
    } catch {
        return $false
    }
}

function Repair-WindowsHealth {
    <#
    .SYNOPSIS
        Ejecuta DISM RestoreHealth + SFC scannow
        PENDIENTE que estaba en README.txt
    #>
    $resultado = @{ DISM = $false; SFC = $false; Mensaje = '' }

    Write-Host "        Ejecutando DISM RestoreHealth..." -ForegroundColor Gray
    Write-Host "        (Esto puede tardar 5-15 minutos)" -ForegroundColor DarkGray

    try {
        $dismResult = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -PassThru -NoNewWindow
        $resultado.DISM = ($dismResult.ExitCode -eq 0)
        Write-FregonatorLog "DISM RestoreHealth: ExitCode $($dismResult.ExitCode)"
    } catch {
        Write-FregonatorLog "Error DISM: $($_.Exception.Message)"
    }

    Write-Host "        Ejecutando SFC scannow..." -ForegroundColor Gray
    Write-Host "        (Esto puede tardar 5-10 minutos)" -ForegroundColor DarkGray

    try {
        $sfcResult = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
        $resultado.SFC = ($sfcResult.ExitCode -eq 0)
        Write-FregonatorLog "SFC scannow: ExitCode $($sfcResult.ExitCode)"
    } catch {
        Write-FregonatorLog "Error SFC: $($_.Exception.Message)"
    }

    if ($resultado.DISM -and $resultado.SFC) {
        $resultado.Mensaje = "Windows reparado correctamente"
    } elseif ($resultado.DISM -or $resultado.SFC) {
        $resultado.Mensaje = "Reparacion parcial completada"
    } else {
        $resultado.Mensaje = "Error en reparacion"
    }

    return $resultado
}

function Start-PatchMyPC {
    $pmpPath = "$env:LOCALAPPDATA\Programs\PatchMyPC\PatchMyPC.exe"
    $pmpPortable = "$PSScriptRoot\..\..\..\tools\PatchMyPC.exe"

    if (Test-Path $pmpPath) {
        Write-Host "    Lanzando PatchMyPC..." -ForegroundColor Cyan
        Start-Process $pmpPath
        return $true
    } elseif (Test-Path $pmpPortable) {
        Write-Host "    Lanzando PatchMyPC (portable)..." -ForegroundColor Cyan
        Start-Process $pmpPortable
        return $true
    }

    Write-Host ""
    Write-Host "    PatchMyPC no esta instalado." -ForegroundColor Yellow
    Write-Host "    Actualiza +500 apps automaticamente (GRATIS para uso personal)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [D] Descargar ahora   [W] Abrir web   [V] Volver" -ForegroundColor White
    Write-Host ""
    Write-Host "    Opcion: " -NoNewline -ForegroundColor Yellow
    $op = Read-Host

    switch ($op.ToUpper()) {
        "D" {
            Write-Host ""
            Write-Host "    Descargando PatchMyPC..." -ForegroundColor Cyan
            $toolsDir = "$PSScriptRoot\..\..\..\tools"
            if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null }
            try {
                Invoke-WebRequest -Uri "https://patchmypc.com/freeupdater/PatchMyPC.exe" -OutFile "$toolsDir\PatchMyPC.exe" -UseBasicParsing
                if (Test-Path "$toolsDir\PatchMyPC.exe") {
                    Write-Host "    [OK] Descargado en: $toolsDir\PatchMyPC.exe" -ForegroundColor Cyan
                    Start-Sleep 1
                    Start-Process "$toolsDir\PatchMyPC.exe"
                    return $true
                }
            } catch {
                Write-Host "    [ERROR] No se pudo descargar: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        "W" { Start-Process "https://patchmypc.com/product/home-updater/" }
    }
    return $false
}

function New-RestorePoint {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "FREGONATOR $(Get-Date -Format 'yyyy-MM-dd')" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
        Write-FregonatorLog "Punto de restauracion creado"
        return $true
    } catch { return $false }
}

# =============================================================================
# LIMPIEZA PROFUNDA - Liberar 5-50 GB
# =============================================================================

function Clear-WinSxS {
    # Limpieza de componentes antiguos de Windows - puede liberar 2-10 GB
    $resultado = @{ Liberado = 0; Exito = $false; Mensaje = '' }
    try {
        Write-Host '        Analizando WinSxS...' -ForegroundColor Gray
        $antes = (Get-Item "$env:windir\WinSxS" -ErrorAction SilentlyContinue | Get-ChildItem -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum

        # DISM cleanup - elimina versiones antiguas de componentes
        $dismResult = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\dism_out.txt" -RedirectStandardError "$env:TEMP\dism_err.txt"

        Start-Sleep 2
        $despues = (Get-Item "$env:windir\WinSxS" -ErrorAction SilentlyContinue | Get-ChildItem -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum

        $resultado.Liberado = [math]::Max(0, $antes - $despues)
        $resultado.Exito = $true
        $resultado.Mensaje = 'Componentes antiguos limpiados'
        Write-FregonatorLog "WinSxS: $([math]::Round($resultado.Liberado/1GB,2)) GB liberados"
    } catch {
        $resultado.Mensaje = 'Error en limpieza WinSxS'
        Write-FregonatorLog "Error WinSxS: $($_.Exception.Message)"
    }
    return $resultado
}

function Clear-WindowsOld {
    # Elimina carpeta Windows.old - puede liberar 10-30 GB
    $resultado = @{ Liberado = 0; Exito = $false; Mensaje = '' }
    $winOldPath = "$env:SystemDrive\Windows.old"

    if (Test-Path $winOldPath) {
        try {
            $size = (Get-ChildItem $winOldPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum

            # Usar metodo seguro con permisos
            takeown /F $winOldPath /R /D Y 2>$null | Out-Null
            icacls $winOldPath /grant administrators:F /T 2>$null | Out-Null
            Remove-Item $winOldPath -Recurse -Force -ErrorAction SilentlyContinue

            $resultado.Liberado = $size
            $resultado.Exito = $true
            $resultado.Mensaje = 'Windows.old eliminado'
            Write-FregonatorLog "Windows.old: $([math]::Round($size/1GB,2)) GB liberados"
        } catch {
            $resultado.Mensaje = 'Error eliminando Windows.old'
            Write-FregonatorLog "Error Windows.old: $($_.Exception.Message)"
        }
    } else {
        $resultado.Exito = $true
        $resultado.Mensaje = 'Windows.old no existe'
    }
    return $resultado
}

function Clear-EventLogs {
    # Limpia logs de eventos de Windows
    $resultado = @{ Liberado = 0; Exito = $false; Mensaje = '' }
    try {
        $logPath = "$env:windir\System32\winevt\Logs"
        $antes = (Get-ChildItem $logPath -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum

        # Limpiar todos los logs de eventos
        wevtutil el | ForEach-Object { wevtutil cl $_ 2>$null }

        $despues = (Get-ChildItem $logPath -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum

        $resultado.Liberado = [math]::Max(0, $antes - $despues)
        $resultado.Exito = $true
        $resultado.Mensaje = 'Logs de eventos limpiados'
        Write-FregonatorLog "Event Logs: $([math]::Round($resultado.Liberado/1MB,0)) MB liberados"
    } catch {
        $resultado.Mensaje = 'Error limpiando logs'
    }
    return $resultado
}

function Clear-MemoryDumps {
    # Elimina archivos de volcado de memoria
    $resultado = @{ Liberado = 0; Exito = $false; Mensaje = '' }
    $dumpPaths = @(
        "$env:windir\MEMORY.DMP"
        "$env:windir\Minidump"
        "$env:LOCALAPPDATA\CrashDumps"
    )

    $totalSize = 0
    foreach ($path in $dumpPaths) {
        if (Test-Path $path) {
            try {
                $size = (Get-Item $path -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($_.PSIsContainer) {
                        (Get-ChildItem $_ -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
                    } else { $_.Length }
                })
                Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                $totalSize += $size
            } catch { }
        }
    }

    $resultado.Liberado = $totalSize
    $resultado.Exito = $true
    $resultado.Mensaje = 'Volcados de memoria eliminados'
    Write-FregonatorLog "Memory dumps: $([math]::Round($totalSize/1MB,0)) MB liberados"
    return $resultado
}

function Disable-Hibernation {
    # Desactiva hibernacion - libera el tamano de la RAM
    $resultado = @{ Liberado = 0; Exito = $false; Mensaje = '' }
    $hiberPath = "$env:SystemDrive\hiberfil.sys"

    try {
        if (Test-Path $hiberPath) {
            $size = (Get-Item $hiberPath -Force -ErrorAction SilentlyContinue).Length
            powercfg /hibernate off 2>$null
            Start-Sleep 1

            if (-not (Test-Path $hiberPath)) {
                $resultado.Liberado = $size
                $resultado.Exito = $true
                $resultado.Mensaje = 'Hibernacion desactivada'
                Write-FregonatorLog "Hibernacion OFF: $([math]::Round($size/1GB,2)) GB liberados"
            }
        } else {
            $resultado.Exito = $true
            $resultado.Mensaje = 'Hibernacion ya estaba desactivada'
        }
    } catch {
        $resultado.Mensaje = 'Error desactivando hibernacion'
    }
    return $resultado
}

function Clear-DeliveryOptimization {
    # Limpia cache de Delivery Optimization
    $resultado = @{ Liberado = 0; Exito = $false; Mensaje = '' }
    $doPath = "$env:windir\SoftwareDistribution\DeliveryOptimization"

    if (Test-Path $doPath) {
        try {
            $size = (Get-ChildItem $doPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum

            Stop-Service -Name "DoSvc" -Force -ErrorAction SilentlyContinue
            Remove-Item "$doPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service -Name "DoSvc" -ErrorAction SilentlyContinue

            $resultado.Liberado = $size
            $resultado.Exito = $true
            $resultado.Mensaje = 'Cache de actualizaciones limpiado'
            Write-FregonatorLog "Delivery Optimization: $([math]::Round($size/1MB,0)) MB liberados"
        } catch { }
    }
    return $resultado
}

# =============================================================================
# RESUMEN HIBRIDO - Tecnico + Usuario
# =============================================================================

function Show-ResumenHibrido {
    param(
        [hashtable]$Resultados,
        [TimeSpan]$Duracion,
        [string]$Modo
    )

    $totalGB = [math]::Round($Resultados.TotalLiberado / 1GB, 2)
    $totalMB = [math]::Round($Resultados.TotalLiberado / 1MB, 0)

    Write-Host ""
    Write-Host "    ╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║                      OPERACION COMPLETADA                       ║" -ForegroundColor Cyan
    Write-Host "    ╠═════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "    ║                                                                 ║" -ForegroundColor Cyan

    # SECCION USUARIO - Lenguaje simple
    Write-Host "    ║  " -ForegroundColor Cyan -NoNewline
    Write-Host "QUE HICIMOS:" -ForegroundColor White -NoNewline
    Write-Host "                                                   ║" -ForegroundColor Cyan

    if ($totalGB -ge 1) {
        Write-Host "    ║    Tu PC ahora tiene $totalGB GB mas de espacio libre           " -NoNewline -ForegroundColor Cyan
        Write-Host "║" -ForegroundColor Cyan
    } else {
        Write-Host "    ║    Tu PC ahora tiene $totalMB MB mas de espacio libre           " -NoNewline -ForegroundColor Cyan
        Write-Host "║" -ForegroundColor Cyan
    }
    Write-Host "    ║    El disco esta listo para clonar o usar normalmente         ║" -ForegroundColor Cyan
    Write-Host "    ║                                                                 ║" -ForegroundColor Cyan

    # SECCION TECNICA - Detalle por area
    Write-Host "    ╠═════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "    ║  " -ForegroundColor Cyan -NoNewline
    Write-Host "DETALLE TECNICO:" -ForegroundColor Yellow -NoNewline
    Write-Host "                                              ║" -ForegroundColor Cyan

    if ($Resultados.WinSxS) {
        $val = [math]::Round($Resultados.WinSxS / 1GB, 2)
        $txt = "    WinSxS: $val GB"
        Write-Host "    ║  $txt$(' ' * (62 - $txt.Length))║" -ForegroundColor Gray
    }
    if ($Resultados.WindowsOld) {
        $val = [math]::Round($Resultados.WindowsOld / 1GB, 2)
        $txt = "    Windows.old: $val GB"
        Write-Host "    ║  $txt$(' ' * (62 - $txt.Length))║" -ForegroundColor Gray
    }
    if ($Resultados.Hibernacion) {
        $val = [math]::Round($Resultados.Hibernacion / 1GB, 2)
        $txt = "    Hibernacion: $val GB"
        Write-Host "    ║  $txt$(' ' * (62 - $txt.Length))║" -ForegroundColor Gray
    }
    if ($Resultados.EventLogs) {
        $val = [math]::Round($Resultados.EventLogs / 1MB, 0)
        $txt = "    Event Logs: $val MB"
        Write-Host "    ║  $txt$(' ' * (62 - $txt.Length))║" -ForegroundColor Gray
    }
    if ($Resultados.MemoryDumps) {
        $val = [math]::Round($Resultados.MemoryDumps / 1MB, 0)
        $txt = "    Memory Dumps: $val MB"
        Write-Host "    ║  $txt$(' ' * (62 - $txt.Length))║" -ForegroundColor Gray
    }
    if ($Resultados.Temporales) {
        $val = [math]::Round($Resultados.Temporales / 1MB, 0)
        $txt = "    Temporales: $val MB"
        Write-Host "    ║  $txt$(' ' * (62 - $txt.Length))║" -ForegroundColor Gray
    }
    if ($Resultados.DeliveryOpt) {
        $val = [math]::Round($Resultados.DeliveryOpt / 1MB, 0)
        $txt = "    Cache Updates: $val MB"
        Write-Host "    ║  $txt$(' ' * (62 - $txt.Length))║" -ForegroundColor Gray
    }

    Write-Host "    ║                                                                 ║" -ForegroundColor Cyan
    $durTxt = "    Duracion: $([math]::Round($Duracion.TotalMinutes, 1)) minutos"
    Write-Host "    ║  $durTxt$(' ' * (62 - $durTxt.Length))║" -ForegroundColor DarkGray

    $logName = if ($script:CurrentLogFile) { $script:CurrentLogFile | Split-Path -Leaf } else { 'N/A' }
    $logTxt = "    Log: $logName"
    if ($logTxt.Length -gt 62) { $logTxt = $logTxt.Substring(0, 59) + "..." }
    Write-Host "    ║  $logTxt$(' ' * (62 - $logTxt.Length))║" -ForegroundColor DarkGray

    Write-Host "    ╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# =============================================================================
# LIMPIEZA PROFUNDA - Liberar 5-50 GB (WinSxS, Windows.old, Hibernacion, etc.)
# =============================================================================

function Start-LimpiezaProfunda {
    Show-Logo -Subtitulo 'LIMPIEZA PROFUNDA - Liberar 5-50 GB'

    # Health Check del disco antes de empezar
    Write-Host "    Analizando estado del disco..." -ForegroundColor Gray
    $healthCheck = Get-SystemHealthCheck
    Show-HealthCheckResult -Health $healthCheck

    # Si hay problemas graves, advertir
    if ($healthCheck.Score -lt 70) {
        Write-Host "    [!] Tu disco tiene problemas. Considera hacer backup antes." -ForegroundColor Red
        Write-Host ""
    }

    Write-Host "    ╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "    ║  ATENCION: Esta limpieza es PROFUNDA y permanente              ║" -ForegroundColor Yellow
    Write-Host "    ║                                                                 ║" -ForegroundColor Yellow
    Write-Host "    ║  Se eliminara:                                                  ║" -ForegroundColor Yellow
    Write-Host '    ║    - WinSxS componentes antiguos (2-10 GB)                      ║' -ForegroundColor White
    Write-Host '    ║    - Windows.old si existe (10-30 GB)                           ║' -ForegroundColor White
    Write-Host '    ║    - Hibernacion OFF (tamano de la RAM)                         ║' -ForegroundColor White
    Write-Host "    ║    - Logs de eventos                                            ║" -ForegroundColor White
    Write-Host "    ║    - Volcados de memoria                                        ║" -ForegroundColor White
    Write-Host "    ║    - Temporales y cache                                         ║" -ForegroundColor White
    Write-Host "    ║                                                                 ║" -ForegroundColor Yellow
    Write-Host "    ║  Puede liberar entre 5-50 GB dependiendo del PC                 ║" -ForegroundColor Cyan
    Write-Host "    ╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Escriba LIMPIAR para confirmar o [V] para volver: " -NoNewline -ForegroundColor Red
    $confirmacion = Read-Host

    if ($confirmacion -ne "LIMPIAR") {
        Write-Host "    Operacion cancelada" -ForegroundColor Yellow
        Start-Sleep 1
        return
    }

    Start-FregonatorLog -Operation "LIMPIEZA-PROFUNDA"
    $script:Stats.StartTime = Get-Date

    $resultados = @{
        TotalLiberado = 0
        WinSxS = 0
        WindowsOld = 0
        Hibernacion = 0
        EventLogs = 0
        MemoryDumps = 0
        Temporales = 0
        DeliveryOpt = 0
    }

    $tareas = @(
        @{ Nombre = 'Windows.old (10-30 GB)'; Funcion = {
            $r = Clear-WindowsOld
            $script:resultados.WindowsOld = $r.Liberado
            $r.Liberado
        }}
        @{ Nombre = 'Hibernacion OFF (RAM)'; Funcion = {
            $r = Disable-Hibernation
            $script:resultados.Hibernacion = $r.Liberado
            $r.Liberado
        }}
        @{ Nombre = 'WinSxS Componentes (2-10 GB)'; Funcion = {
            $r = Clear-WinSxS
            $script:resultados.WinSxS = $r.Liberado
            $r.Liberado
        }}
        @{ Nombre = 'Logs de eventos'; Funcion = {
            $r = Clear-EventLogs
            $script:resultados.EventLogs = $r.Liberado
            $r.Liberado
        }}
        @{ Nombre = 'Volcados de memoria'; Funcion = {
            $r = Clear-MemoryDumps
            $script:resultados.MemoryDumps = $r.Liberado
            $r.Liberado
        }}
        @{ Nombre = 'Temporales y cache'; Funcion = {
            $lib = Clear-TempFiles -Silent
            $script:resultados.Temporales = $lib
            $lib
        }}
        @{ Nombre = 'Cache de actualizaciones'; Funcion = {
            $r = Clear-DeliveryOptimization
            $script:resultados.DeliveryOpt = $r.Liberado
            $r.Liberado
        }}
        @{ Nombre = 'Papelera de reciclaje'; Funcion = { Clear-RecycleBinSafe; 0 }}
    )

    # Variable de script para acceso en scriptblocks
    $script:resultados = $resultados

    Write-Host ""
    $total = $tareas.Count
    $i = 0

    foreach ($tarea in $tareas) {
        $i++
        $pct = [math]::Floor(($i / $total) * 100)
        $barWidth = 40
        $filled = [math]::Floor($pct * $barWidth / 100)
        $bar = ('█' * $filled) + ('░' * ($barWidth - $filled))

        Write-Host "`r    [$bar] $pct% - $($tarea.Nombre)...                              " -NoNewline -ForegroundColor Cyan

        $liberado = & $tarea.Funcion
        $script:resultados.TotalLiberado += $liberado
    }

    Write-Host ""

    $duracion = (Get-Date) - $script:Stats.StartTime

    # Actualizar resultados finales
    $resultados = $script:resultados

    Write-FregonatorLog "LIMPIEZA-PROFUNDA completado: $([math]::Round($resultados.TotalLiberado/1GB,2)) GB liberados en $([math]::Round($duracion.TotalMinutes,1)) min"

    Show-ResumenHibrido -Resultados $resultados -Duracion $duracion -Modo "LIMPIEZA-PROFUNDA"

    Write-Host "    [V] Volver   [X] Salir" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Opcion: " -NoNewline -ForegroundColor Yellow
    Read-Host
}

# =============================================================================
# UN CLICK - 8 barras apiladas + barra global + frases random
# =============================================================================

# Frases random estilo "thinking" MEMMEM (sin palabras que asusten)
$script:FrasesThinking = @(
    "Pensandoing", "Limpiandoing", "Optimizandoing", "Traballandoing",
    "Escaneandoing", "Procesanding", "Calculanding", "Analizanding",
    "Tuneanding", "Ordenanding", "Cafeinanding", "Preparanding",
    "Molanding", "Curranding", "Vibeanding", "Chillanding",
    "Nalaing", "Ladrandoing", "Aturuxanding", "Brillanding",
    "Mejorandoing", "Acelerandoing", "Pulindoing", "Afinanding",
    "Freganding", "Barriending", "Aspiranding", "Desatascanding",
    "Turboanding", "Nitroanding", "Boostingando", "Poweranding",
    "Hackeanding", "Debuganding", "Compilanding", "Deployanding",
    "Galaxeanding", "Cosmicanding", "Quantumanding", "Matrixanding",
    "Rockanding", "Metalanding", "Punkanding", "Synthanding",
    "Pizzanding", "Kebabanding", "Tacoing", "Sushianding",
    "Siestando", "Yoganding", "Zenanding", "Meditanding",
    "Mikianding", "Donalding", "Goofyanding", "Plutoanding",
    "Jedianding", "Sithanding", "Forcingando", "Sabreanding",
    "Galleganding", "Morrinanding", "Meigandering", "Retrancanding"
)

$script:ColoresArcoiris = @("Red", "DarkYellow", "Yellow", "Green", "Cyan", "Blue", "Magenta")

function Get-FraseRandom {
    return $script:FrasesThinking | Get-Random
}

function Start-OneClick {
    Show-Logo -Subtitulo "UN CLICK - OPTIMIZACION PARALELA"
    Update-Monitor -Etapa "Limpieza Rapida" -Progreso 5 -Total 8 -Log "Iniciando limpieza rapida..."

    # Capturar espacio libre ANTES
    $script:Stats.BytesAntes = Get-DiscoLibre

    # Inicializar sistema de reportes
    Start-FregonatorLog -Operation "UN CLICK PARALELO"
    $script:Stats.StartTime = Get-Date
    $script:Stats.TotalLiberado = 0
    $script:TaskResults = @()

    # ADVERTENCIA para PCs desactualizados
    Write-Host ""
    Write-Host "    [!] NOTA: En PCs desactualizados, winget y Windows Update pueden" -ForegroundColor Yellow
    Write-Host "        tardar varios minutos. Esto es NORMAL. Pulsa [ESC] para abortar." -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Milliseconds 1500

    $tareas = @(
        @{ Nombre = "Liberando RAM"; Detalle = "Optimizando Working Sets..."; Codigo = { [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect(); "OK" } }
        @{ Nombre = "Limpiando temporales"; Detalle = "Eliminando: %TEMP%\*.tmp, *.log, *.cache"; Codigo = {
            $t = 0; @("$env:TEMP","$env:windir\Temp") | ForEach-Object {
                if (Test-Path $_) { Get-ChildItem $_ -Recurse -Force -EA 0 | ForEach-Object { $t += $_.Length; Remove-Item $_.FullName -Force -Recurse -EA 0 } }
            }; $t
        }}
        @{ Nombre = "Vaciando papelera"; Detalle = "Vaciando: Papelera de reciclaje (todas las unidades)"; Codigo = { Clear-RecycleBin -Force -EA 0; "OK" } }
        @{ Nombre = "Limpiando cache DNS"; Detalle = "Ejecutando: ipconfig /flushdns"; Codigo = { ipconfig /flushdns 2>&1 | Out-Null; "OK" } }
        @{ Nombre = "Optimizando discos"; Detalle = "Optimizando: TRIM en unidades SSD (C:, D:...)"; Codigo = { Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | ForEach-Object { Optimize-Volume -DriveLetter $_.DriveLetter -ReTrim -EA 0 }; "OK" } }
        @{ Nombre = "Alto rendimiento"; Detalle = "Activando: Plan de energia Alto Rendimiento"; Codigo = { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null; "OK" } }
        @{ Nombre = "Actualizando apps"; Detalle = "Ejecutando: winget upgrade --all (espera...)"; Codigo = {
            if (Get-Command winget -EA 0) {
                $p = Start-Process winget -ArgumentList "upgrade --all --accept-source-agreements --accept-package-agreements --silent" -NoNewWindow -PassThru
                if (-not $p.WaitForExit(180000)) { $p.Kill() }  # Timeout 180s (3 min) para PCs lentos
            }; "OK"
        }}
        @{ Nombre = "Windows Update"; Detalle = "Ejecutando: UsoClient.exe StartScan"; Codigo = { Start-Process UsoClient.exe -ArgumentList "StartScan" -NoNewWindow -EA 0; "OK" } }
    )

    $total = $tareas.Count
    $anchoBar = 25

    Write-Host ""
    $anchoCaja = 76
    $textoHeader = "  EJECUCION PARALELA: 8 tareas simultaneas"
    $textoESC = "[ESC] Abortar"
    $espacios = $anchoCaja - $textoHeader.Length - $textoESC.Length
    $lineaHeader = "$textoHeader$(' ' * $espacios)$textoESC"
    Write-Host "    ╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║$lineaHeader║" -ForegroundColor White
    Write-Host "    ╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Mostrar las 8 lineas iniciales (pendientes)
    for ($i = 0; $i -lt $total; $i++) {
        $num = "[$($i+1)/$total]"
        $barVacia = "░" * $anchoBar
        Write-Host "    $num $($tareas[$i].Nombre.PadRight(22)) [$barVacia] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Pendiente" -ForegroundColor DarkGray
    }
    Write-Host ""
    $barGlobalVacia = "░" * 50
    Write-Host "    GLOBAL: [$barGlobalVacia] 0%  (0/$total)" -ForegroundColor DarkGray
    Write-Host ""

    # Guardar posicion para actualizar in-place
    $lineaBase = (Get-CursorTopSafe) - $total - 3

    # LANZAR TODAS LAS TAREAS EN PARALELO
    $startTime = Get-Date
    $jobs = @()
    $jobStartTimes = @{}  # Registrar cuando empezo cada tarea
    for ($i = 0; $i -lt $total; $i++) {
        $jobs += Start-Job -ScriptBlock $tareas[$i].Codigo -Name "Task$i"
        $jobStartTimes[$i] = Get-Date  # Todas empiezan ahora (paralelas)
    }

    # Array para trackear completados y frames de animacion
    $completados = @{}
    $frames = @{}
    for ($i = 0; $i -lt $total; $i++) { $frames[$i] = 0 }

    # Simbolos rotando para indicador de actividad
    $spinners = @('+', '-', '*', '/', '+', '-', '*', '/')

    # Variable para controlar abort
    $abortado = $false

    # Loop de animacion mientras hay jobs corriendo
    while (($jobs | Where-Object { $_.State -eq 'Running' }).Count -gt 0) {

        # Detectar ESC para abortar
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'Escape') {
                $abortado = $true
                # Detener todos los jobs
                $jobs | Stop-Job -ErrorAction SilentlyContinue
                $jobs | Remove-Job -Force -ErrorAction SilentlyContinue

                Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 2)
                Write-Host ""
                Write-Host "    [!] ABORTADO por el usuario                                              " -ForegroundColor Red
                Write-Host ""
                Write-FregonatorLog "ABORTADO por el usuario (ESC)"
                break
            }
        }

        for ($i = 0; $i -lt $total; $i++) {
            $job = $jobs[$i]
            $num = "[$($i+1)/$total]"

            Set-CursorPositionSafe -X 0 -Y ($lineaBase + $i)

            if ($job.State -eq 'Running') {
                # Tarea corriendo: mostrar animacion + tiempo transcurrido
                $frame = $frames[$i]
                $progreso = ($frame % ($anchoBar + 1))
                $barLlena = "█" * $progreso
                $barVacia = "░" * ($anchoBar - $progreso)
                $frase = Get-FraseRandom
                $spinner = $spinners[$frame % $spinners.Count]

                # Calcular tiempo que lleva esta tarea
                $taskElapsed = (Get-Date) - $jobStartTimes[$i]
                $taskSecs = [math]::Floor($taskElapsed.TotalSeconds)
                $taskTimeStr = "{0:00}:{1:00}" -f [int][math]::Floor($taskSecs / 60), [int]($taskSecs % 60)

                # Color segun tiempo (>30s = amarillo, >60s = naranja)
                $timeColor = "DarkGray"
                if ($taskSecs -gt 60) { $timeColor = "DarkYellow" }
                elseif ($taskSecs -gt 30) { $timeColor = "Yellow" }

                Write-Host "    $num $($tareas[$i].Nombre.PadRight(22)) [" -NoNewline -ForegroundColor White
                Write-Host "$barLlena" -NoNewline -ForegroundColor Cyan
                Write-Host "$barVacia" -NoNewline -ForegroundColor DarkGray
                Write-Host "] " -NoNewline -ForegroundColor White
                Write-Host "$spinner " -NoNewline -ForegroundColor Yellow
                Write-Host "$taskTimeStr " -NoNewline -ForegroundColor $timeColor
                Write-Host "$($frase.PadRight(12))   " -NoNewline -ForegroundColor DarkGray
                
                # Actualizar monitor con tarea en curso (con detalle de actividad real)
                $detalleActividad = if ($tareas[$i].Detalle) { $tareas[$i].Detalle } else { $tareas[$i].Nombre }
                Update-Monitor -Archivo $detalleActividad

                $frames[$i]++
            }
            elseif (-not $completados.ContainsKey($i)) {
                # Tarea recien completada
                $completados[$i] = $true
                $barCompleta = "█" * $anchoBar
                Write-Host "    $num $($tareas[$i].Nombre.PadRight(22)) [" -NoNewline -ForegroundColor White
                Write-Host "$barCompleta" -NoNewline -ForegroundColor Cyan
                Write-Host "] " -NoNewline -ForegroundColor White
                Write-Host "OK                      " -ForegroundColor Cyan

                # Registrar resultado
                $resultado = Receive-Job -Job $job -ErrorAction SilentlyContinue
                $bytes = 0
                if ($i -eq 1 -and $resultado -is [long]) { $bytes = $resultado; $script:Stats.TotalLiberado += $bytes }
                Add-TaskResult -Nombre $tareas[$i].Nombre -Estado "OK" -BytesLiberados $bytes
                
                # Actualizar monitor con tarea completada
                Update-Monitor -Archivo $tareas[$i].Nombre -Log "Completado: $($tareas[$i].Nombre)"
            }
        }
        
        # Detectar ABORT desde el Monitor GUI
        if (Test-Path "$env:PUBLIC\fregonator_abort.flag") {
            Remove-Item "$env:PUBLIC\fregonator_abort.flag" -Force -ErrorAction SilentlyContinue
            $abortado = $true
            $jobs | Stop-Job -ErrorAction SilentlyContinue
            Update-Monitor -Etapa "ABORTADO" -Log "Abortado por el usuario"
            Write-Host ""
            Write-Host "    [!] ABORTADO desde Monitor GUI                                           " -ForegroundColor Red
            Write-Host ""
            break
        }

        # Actualizar barra global + tiempo debajo (% en tiempo real interpolado)
        $numCompletados = $completados.Count
        $elapsed = (Get-Date) - $startTime

        # Calcular % interpolado en tiempo real
        $pctBase = ($numCompletados / $total) * 100
        $pctExtra = 0
        $remainingStr = "calculando..."
        if ($numCompletados -gt 0) {
            $avgPerTask = $elapsed.TotalSeconds / $numCompletados
            # Estimar progreso parcial de tareas en curso
            $tareasEnCurso = ($jobs | Where-Object { $_.State -eq 'Running' }).Count
            if ($tareasEnCurso -gt 0 -and $avgPerTask -gt 0) {
                $tiempoDesdeUltima = $elapsed.TotalSeconds - ($numCompletados * $avgPerTask)
                $progresoTareaActual = [math]::Min(1, $tiempoDesdeUltima / $avgPerTask)
                $pctExtra = ($progresoTareaActual / $total) * 100
            }
            $remaining = [TimeSpan]::FromSeconds([math]::Max(0, $avgPerTask * ($total - $numCompletados) - ($elapsed.TotalSeconds - $numCompletados * $avgPerTask)))
            $remainingStr = "{0:mm\:ss}" -f $remaining
        }

        $pctGlobal = [math]::Min(99, [math]::Round($pctBase + $pctExtra))
        if ($numCompletados -eq $total) { $pctGlobal = 100 }
        
        # Actualizar monitor externo
        Update-Monitor -Progreso $pctGlobal -Archivos $numCompletados -Total $total -Log "Tarea $numCompletados de $total"

        $barLlena = "█" * [math]::Floor($pctGlobal / 2)
        $barVacia = "░" * (50 - [math]::Floor($pctGlobal / 2))
        $elapsedStr = "{0:mm\:ss}" -f $elapsed

        Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 1)
        Write-Host "    GLOBAL: [$barLlena$barVacia] $pctGlobal% ($numCompletados/$total)                    " -ForegroundColor Cyan
        Write-Host ""
        Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 3)
        Write-Host "                                                                 $elapsedStr (Tiempo transcurrido)            " -ForegroundColor DarkGray
        Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 4)
        Write-Host "                                                                 $remainingStr (Tiempo restante aproximado)   " -ForegroundColor DarkGray

        Start-Sleep -Milliseconds 250
    }

    # Si fue abortado, mostrar opciones y salir
    if ($abortado) {
        Complete-FregonatorLog
        Write-Host "    ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "    ║  [V] Volver al menu                [X] Salir                          ║" -ForegroundColor Gray
        Write-Host "    ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "    Opcion: " -NoNewline -ForegroundColor Yellow
        $opcion = Read-Host
        if ($opcion.ToUpper() -eq "X") { [Environment]::Exit(0) }
        return
    }

    # Marcar las ultimas que terminaron (por si acaso)
    for ($i = 0; $i -lt $total; $i++) {
        if (-not $completados.ContainsKey($i)) {
            $completados[$i] = $true
            $num = "[$($i+1)/$total]"
            $barCompleta = "█" * $anchoBar
            Set-CursorPositionSafe -X 0 -Y ($lineaBase + $i)
            Write-Host "    $num $($tareas[$i].Nombre.PadRight(22)) [" -NoNewline -ForegroundColor White
            Write-Host "$barCompleta" -NoNewline -ForegroundColor Cyan
            Write-Host "] " -NoNewline -ForegroundColor White
            Write-Host "OK                      " -ForegroundColor Cyan

            $resultado = Receive-Job -Job $jobs[$i] -ErrorAction SilentlyContinue
            $bytes = 0
            if ($i -eq 1 -and $resultado -is [long]) { $bytes = $resultado; $script:Stats.TotalLiberado += $bytes }
            Add-TaskResult -Nombre $tareas[$i].Nombre -Estado "OK" -BytesLiberados $bytes
        }
    }

    # Actualizar barra global al 100%
    Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 1)
    $barGlobalCompleta = "█" * 50
    Write-Host "    GLOBAL: [$barGlobalCompleta] 100%  ($total/$total)    " -ForegroundColor Cyan

    # Limpiar jobs
    $jobs | Remove-Job -Force -ErrorAction SilentlyContinue

    # Limpiar lineas de tiempo residuales
    $limpiar = " " * 150
    Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 3)
    Write-Host $limpiar
    Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 4)
    Write-Host $limpiar
    Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 3)

    # Capturar espacio libre DESPUES
    $script:Stats.BytesDespues = Get-DiscoLibre

    # Generar reportes
    Show-FregonatorResumen
    Show-Comparativa
    $htmlPath = Export-FregonatorHTML
    Complete-FregonatorLog

    # Guardar en historial
    $duracion = (Get-Date) - $script:Stats.StartTime
    $totalBytes = ($script:TaskResults | ForEach-Object { $_.BytesLiberados } | Measure-Object -Sum).Sum
    Add-LimpiezaHistorial -Modo "Rapida" -BytesLiberados $totalBytes -Tareas $script:TaskResults.Count -Duracion $duracion

    # Notificacion Windows
    $totalMB = [math]::Round($totalBytes / 1MB, 0)
    Update-Monitor -Etapa "Completado" -Progreso 100 -EspacioMB $totalMB -Log "Limpieza finalizada: $totalMB MB liberados" -Terminado

    # En modo GUI: terminar limpiamente sin menus
    if ($script:ModoGUI) {
        return
    }

    Show-WindowsNotification -Titulo (T 'notificacionTitulo') -Mensaje "$(T 'limpiezaFinalizada'): $totalMB MB $(T 'espacioLiberado')"

    Write-Host ""
    Write-Host "    ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║  [H] Abrir informe HTML    [L] Abrir carpeta logs                     ║" -ForegroundColor White
    Write-Host "    ║  [V] Volver al menu        [X] Salir                                  ║" -ForegroundColor Gray
    Write-Host "    ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Opcion: " -NoNewline -ForegroundColor Yellow

    $opcion = Read-Host
    switch ($opcion.ToUpper()) {
        "H" {
            if (Test-Path $htmlPath) {
                Start-Process $htmlPath
            }
        }
        "L" {
            Start-Process explorer.exe -ArgumentList $script:CONFIG.LogPath
        }
        "X" {
            [Environment]::Exit(0)
        }
    }
}

# =============================================================================
# UN CLICK AVANZADA - TODO incluido (basicas + avanzadas)
# =============================================================================

function Start-OneClickAvanzada {
    Show-Logo -Subtitulo "UN CLICK AVANZADA - OPTIMIZACION TOTAL"
    Update-Monitor -Etapa "Limpieza Avanzada" -Progreso 5 -Total 13 -Log "Iniciando limpieza avanzada..."

    # Capturar espacio libre ANTES
    $script:Stats.BytesAntes = Get-DiscoLibre

    # Inicializar sistema de reportes
    Start-FregonatorLog -Operation "UN CLICK AVANZADA"
    $script:Stats.StartTime = Get-Date
    $script:Stats.TotalLiberado = 0
    $script:TaskResults = @()

    # ADVERTENCIA para PCs desactualizados
    Write-Host ""
    Write-Host "    [!] NOTA: En PCs desactualizados, winget y Windows Update pueden" -ForegroundColor Yellow
    Write-Host "        tardar varios minutos. Esto es NORMAL. Pulsa [ESC] para abortar." -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Milliseconds 1500

    # PASO 1: Punto de restauracion (antes de todo)
    Write-Host ""
    Write-Host "    [!] Creando punto de restauracion (por seguridad)..." -ForegroundColor Yellow
    try {
        $null = Checkpoint-Computer -Description "FREGONATOR Pre-Optimizacion" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop -WarningAction SilentlyContinue 2>&1
        Write-Host "    [OK] Punto de restauracion creado" -ForegroundColor Cyan
        Add-TaskResult -Nombre "Punto restauracion" -Estado "OK"
    } catch {
        # Ya existe uno reciente o no se pudo crear
        Write-Host "    [OK] Ya existe un punto reciente (continua)" -ForegroundColor DarkGray
        Add-TaskResult -Nombre "Punto restauracion" -Estado "SKIP"
    }
    Start-Sleep -Milliseconds 500

    # PASO 2: Todas las tareas en paralelo (con detalles para el Monitor)
    $tareas = @(
        # Basicas (8)
        @{ Nombre = "Liberando RAM"; Detalle = "Optimizando Working Sets..."; Codigo = { [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect(); "OK" } }
        @{ Nombre = "Limpiando temporales"; Detalle = "Eliminando: %TEMP%\*.tmp, *.log, *.cache"; Codigo = {
            $t = 0; @("$env:TEMP","$env:windir\Temp","$env:LOCALAPPDATA\Temp") | ForEach-Object {
                if (Test-Path $_) { Get-ChildItem $_ -Recurse -Force -EA 0 | ForEach-Object { $t += $_.Length; Remove-Item $_.FullName -Force -Recurse -EA 0 } }
            }; $t
        }}
        @{ Nombre = "Vaciando papelera"; Detalle = "Vaciando: Papelera de reciclaje (todas las unidades)"; Codigo = { Clear-RecycleBin -Force -EA 0; "OK" } }
        @{ Nombre = "Limpiando cache DNS"; Detalle = "Ejecutando: ipconfig /flushdns"; Codigo = { ipconfig /flushdns 2>&1 | Out-Null; "OK" } }
        @{ Nombre = "Optimizando discos"; Detalle = "Optimizando: TRIM en unidades SSD (C:, D:...)"; Codigo = { Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | ForEach-Object { Optimize-Volume -DriveLetter $_.DriveLetter -ReTrim -EA 0 }; "OK" } }
        @{ Nombre = "Alto rendimiento"; Detalle = "Activando: Plan de energia Alto Rendimiento"; Codigo = { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null; "OK" } }
        @{ Nombre = "Actualizando apps"; Detalle = "Ejecutando: winget upgrade --all (espera...)"; Codigo = {
            if (Get-Command winget -EA 0) {
                $p = Start-Process winget -ArgumentList "upgrade --all --accept-source-agreements --accept-package-agreements --silent" -NoNewWindow -PassThru
                if (-not $p.WaitForExit(180000)) { $p.Kill() }  # Timeout 180s (3 min) para PCs lentos
            }; "OK"
        }}
        @{ Nombre = "Windows Update"; Detalle = "Ejecutando: UsoClient.exe StartScan"; Codigo = { Start-Process UsoClient.exe -ArgumentList "StartScan" -NoNewWindow -EA 0; "OK" } }
        # Avanzadas
        @{ Nombre = "Limpiando registro MRU"; Detalle = "Limpiando: HKCU\...\OpenSaveMRU, RunMRU"; Codigo = {
            @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSaveMRU",
              "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
              "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths") | ForEach-Object {
                if (Test-Path $_) { Remove-Item $_ -Recurse -Force -EA 0 }
            }; "OK"
        }}
        @{ Nombre = "Matando procesos"; Detalle = "Cerrando: OneDrive, GameBar, Cortana, YourPhone..."; Codigo = {
            @("OneDrive","GameBar","Cortana","YourPhone","GrooveMusic") | ForEach-Object {
                Get-Process -Name $_ -EA 0 | Stop-Process -Force -EA 0
            }; "OK"
        }}
        @{ Nombre = "Telemetria OFF"; Detalle = "Desactivando: DiagTrack, dmwappushservice"; Codigo = {
            @("DiagTrack","dmwappushservice") | ForEach-Object {
                Stop-Service $_ -Force -EA 0; Set-Service $_ -StartupType Disabled -EA 0
            }; "OK"
        }}
        @{ Nombre = "Eliminando bloatware"; Detalle = "Desinstalando: CandyCrush, BubbleWitch, Solitaire, Bing..."; Codigo = {
            @("*CandyCrush*","*BubbleWitch*","*FarmVille*","*Disney*","*Microsoft.MicrosoftSolitaireCollection*","*Microsoft.Bing*","*Microsoft.Xbox*","*Microsoft.YourPhone*") | ForEach-Object {
                Get-AppxPackage $_ -EA 0 | Remove-AppxPackage -EA 0
            }; "OK"
        }}
        @{ Nombre = "Efectos visuales"; Detalle = "Optimizando: Efectos visuales de Windows"; Codigo = {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -EA 0; "OK"
        }}
    )

    $total = $tareas.Count
    $anchoBar = 25
    $spinners = @('+', '-', '*', '/')

    Write-Host ""
    $anchoCaja = 76
    $textoHeader = "  EJECUCION PARALELA: $total tareas (basicas + avanzadas)"
    $textoESC = "[ESC] Abortar"
    $espacios = $anchoCaja - $textoHeader.Length - $textoESC.Length
    $lineaHeader = "$textoHeader$(' ' * $espacios)$textoESC"
    Write-Host "    ╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║$lineaHeader║" -ForegroundColor White
    Write-Host "    ╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Mostrar lineas iniciales
    for ($i = 0; $i -lt $total; $i++) {
        $num = "[$($i+1)/$total]".PadRight(7)
        $barVacia = "░" * $anchoBar
        Write-Host "    $num $($tareas[$i].Nombre.PadRight(22)) [$barVacia] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Pendiente" -ForegroundColor DarkGray
    }
    Write-Host ""
    $barGlobalVacia = "░" * 50
    Write-Host "    GLOBAL: [$barGlobalVacia] 0%  (0/$total)" -ForegroundColor DarkGray
    Write-Host ""

    $lineaBase = (Get-CursorTopSafe) - $total - 3

    # Lanzar todas en paralelo
    $startTime = Get-Date
    $jobs = @()
    $jobStartTimes = @{}  # Registrar cuando empezo cada tarea
    for ($i = 0; $i -lt $total; $i++) {
        $jobs += Start-Job -ScriptBlock $tareas[$i].Codigo -Name "Task$i"
        $jobStartTimes[$i] = Get-Date  # Todas empiezan ahora (paralelas)
    }

    $completados = @{}
    $frames = @{}
    for ($i = 0; $i -lt $total; $i++) { $frames[$i] = 0 }

    # Simbolos rotando
    $spinners = @('+', '-', '*', '/', '+', '-', '*', '/')

    # Variable para controlar abort
    $abortado = $false

    # Loop de animacion
    while (($jobs | Where-Object { $_.State -eq 'Running' }).Count -gt 0) {

        # Detectar ESC para abortar
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'Escape') {
                $abortado = $true
                $jobs | Stop-Job -ErrorAction SilentlyContinue
                $jobs | Remove-Job -Force -ErrorAction SilentlyContinue

                Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 2)
                Write-Host ""
                Write-Host "    [!] ABORTADO por el usuario                                              " -ForegroundColor Red
                Write-Host ""
                Write-FregonatorLog "ABORTADO por el usuario (ESC)"
                break
            }
        }

        for ($i = 0; $i -lt $total; $i++) {
            $job = $jobs[$i]
            $num = "[$($i+1)/$total]".PadRight(7)

            Set-CursorPositionSafe -X 0 -Y ($lineaBase + $i)

            if ($job.State -eq 'Running') {
                # Tarea corriendo: mostrar animacion + tiempo transcurrido
                $frame = $frames[$i]
                $progreso = ($frame % ($anchoBar + 1))
                $barLlena = "█" * $progreso
                $barVacia = "░" * ($anchoBar - $progreso)
                $frase = Get-FraseRandom
                $spinner = $spinners[$frame % $spinners.Count]

                # Calcular tiempo que lleva esta tarea
                $taskElapsed = (Get-Date) - $jobStartTimes[$i]
                $taskSecs = [math]::Floor($taskElapsed.TotalSeconds)
                $taskTimeStr = "{0:00}:{1:00}" -f [int][math]::Floor($taskSecs / 60), [int]($taskSecs % 60)

                # Color segun tiempo (>30s = amarillo, >60s = naranja)
                $timeColor = "DarkGray"
                if ($taskSecs -gt 60) { $timeColor = "DarkYellow" }
                elseif ($taskSecs -gt 30) { $timeColor = "Yellow" }

                Write-Host "    $num $($tareas[$i].Nombre.PadRight(22)) [" -NoNewline -ForegroundColor White
                Write-Host "$barLlena" -NoNewline -ForegroundColor Cyan
                Write-Host "$barVacia" -NoNewline -ForegroundColor DarkGray
                Write-Host "] " -NoNewline -ForegroundColor White
                Write-Host "$spinner " -NoNewline -ForegroundColor Yellow
                Write-Host "$taskTimeStr " -NoNewline -ForegroundColor $timeColor
                Write-Host "$($frase.PadRight(12))   " -NoNewline -ForegroundColor DarkGray
                
                # Actualizar monitor con tarea en curso (con detalle de actividad real)
                $detalleActividad = if ($tareas[$i].Detalle) { $tareas[$i].Detalle } else { $tareas[$i].Nombre }
                Update-Monitor -Archivo $detalleActividad

                $frames[$i]++
            }
            elseif (-not $completados.ContainsKey($i)) {
                $completados[$i] = $true
                $barCompleta = "█" * $anchoBar
                Write-Host "    $num $($tareas[$i].Nombre.PadRight(22)) [" -NoNewline -ForegroundColor White
                Write-Host "$barCompleta" -NoNewline -ForegroundColor Cyan
                Write-Host "] " -NoNewline -ForegroundColor White
                Write-Host "OK                      " -ForegroundColor Cyan

                $resultado = Receive-Job -Job $job -ErrorAction SilentlyContinue
                $bytes = 0
                if ($i -eq 1 -and $resultado -is [long]) { $bytes = $resultado; $script:Stats.TotalLiberado += $bytes }
                Add-TaskResult -Nombre $tareas[$i].Nombre -Estado "OK" -BytesLiberados $bytes
                
                # Actualizar monitor con tarea completada
                Update-Monitor -Archivo $tareas[$i].Nombre -Log "Completado: $($tareas[$i].Nombre)"
            }
        }
        
        # Detectar ABORT desde el Monitor GUI
        if (Test-Path "$env:PUBLIC\fregonator_abort.flag") {
            Remove-Item "$env:PUBLIC\fregonator_abort.flag" -Force -ErrorAction SilentlyContinue
            $abortado = $true
            $jobs | Stop-Job -ErrorAction SilentlyContinue
            Update-Monitor -Etapa "ABORTADO" -Log "Abortado por el usuario"
            Write-Host ""
            Write-Host "    [!] ABORTADO desde Monitor GUI                                           " -ForegroundColor Red
            Write-Host ""
            break
        }

        # Actualizar barra global + tiempo debajo (% en tiempo real interpolado)
        $numCompletados = $completados.Count
        $elapsed = (Get-Date) - $startTime

        # Calcular % interpolado en tiempo real
        $pctBase = ($numCompletados / $total) * 100
        $pctExtra = 0
        $remainingStr = "calculando..."
        if ($numCompletados -gt 0) {
            $avgPerTask = $elapsed.TotalSeconds / $numCompletados
            # Estimar progreso parcial de tareas en curso
            $tareasEnCurso = ($jobs | Where-Object { $_.State -eq 'Running' }).Count
            if ($tareasEnCurso -gt 0 -and $avgPerTask -gt 0) {
                $tiempoDesdeUltima = $elapsed.TotalSeconds - ($numCompletados * $avgPerTask)
                $progresoTareaActual = [math]::Min(1, $tiempoDesdeUltima / $avgPerTask)
                $pctExtra = ($progresoTareaActual / $total) * 100
            }
            $remaining = [TimeSpan]::FromSeconds([math]::Max(0, $avgPerTask * ($total - $numCompletados) - ($elapsed.TotalSeconds - $numCompletados * $avgPerTask)))
            $remainingStr = "{0:mm\:ss}" -f $remaining
        }

        $pctGlobal = [math]::Min(99, [math]::Round($pctBase + $pctExtra))
        if ($numCompletados -eq $total) { $pctGlobal = 100 }
        
        # Actualizar monitor externo
        Update-Monitor -Progreso $pctGlobal -Archivos $numCompletados -Total $total -Log "Tarea $numCompletados de $total"

        $barLlena = "█" * [math]::Floor($pctGlobal / 2)
        $barVacia = "░" * (50 - [math]::Floor($pctGlobal / 2))
        $elapsedStr = "{0:mm\:ss}" -f $elapsed

        Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 1)
        Write-Host "    GLOBAL: [$barLlena$barVacia] $pctGlobal% ($numCompletados/$total)                    " -ForegroundColor Cyan
        Write-Host ""
        Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 3)
        Write-Host "                                                                 $elapsedStr (Tiempo transcurrido)            " -ForegroundColor DarkGray
        Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 4)
        Write-Host "                                                                 $remainingStr (Tiempo restante aproximado)   " -ForegroundColor DarkGray

        Start-Sleep -Milliseconds 250
    }

    # Si fue abortado, mostrar opciones y salir (NO marcar tareas pendientes)
    if ($abortado) {
        Complete-FregonatorLog
        Write-Host "    ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "    ║  [V] Volver al menu                [X] Salir                          ║" -ForegroundColor Gray
        Write-Host "    ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "    Opcion: " -NoNewline -ForegroundColor Yellow
        $opcion = Read-Host
        if ($opcion.ToUpper() -eq "X") { [Environment]::Exit(0) }
        return
    }

    # Marcar ultimas completadas (solo si NO fue abortado)
    for ($i = 0; $i -lt $total; $i++) {
        if (-not $completados.ContainsKey($i)) {
            $completados[$i] = $true
            $num = "[$($i+1)/$total]".PadRight(7)
            $barCompleta = "█" * $anchoBar
            Set-CursorPositionSafe -X 0 -Y ($lineaBase + $i)
            Write-Host "    $num $($tareas[$i].Nombre.PadRight(22)) [" -NoNewline -ForegroundColor White
            Write-Host "$barCompleta" -NoNewline -ForegroundColor Cyan
            Write-Host "] " -NoNewline -ForegroundColor White
            Write-Host "OK                      " -ForegroundColor Cyan

            $resultado = Receive-Job -Job $jobs[$i] -ErrorAction SilentlyContinue
            $bytes = 0
            if ($i -eq 1 -and $resultado -is [long]) { $bytes = $resultado; $script:Stats.TotalLiberado += $bytes }
            Add-TaskResult -Nombre $tareas[$i].Nombre -Estado "OK" -BytesLiberados $bytes
        }
    }

    Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 1)
    $barGlobalCompleta = "█" * 50
    Write-Host "    GLOBAL: [$barGlobalCompleta] 100%  ($total/$total)    " -ForegroundColor Cyan

    $jobs | Remove-Job -Force -ErrorAction SilentlyContinue

    # Limpiar lineas de tiempo residuales
    $limpiar = " " * 150
    Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 3)
    Write-Host $limpiar
    Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 4)
    Write-Host $limpiar
    Set-CursorPositionSafe -X 0 -Y ($lineaBase + $total + 3)

    # PASO 3: Opciones adicionales (DISM+SFC o Limpieza Profunda)
    # SOLO mostrar en modo interactivo (no en modo GUI)
    if (-not $script:ModoGUI) {
        Write-Host ""
        Write-Host "    ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "    ║                     OPCIONES ADICIONALES                              ║" -ForegroundColor Yellow
        Write-Host "    ╠═══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
        Write-Host "    ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "    ║  [D] DISM + SFC          Reparar Windows (15-30 min)                  ║" -ForegroundColor White
        Write-Host "    ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "    ║  [P] LIMPIEZA PROFUNDA   Liberar 5-50 GB adicionales:                 ║" -ForegroundColor Cyan
        Write-Host "    ║                          - WinSxS componentes (2-10 GB)               ║" -ForegroundColor Gray
        Write-Host "    ║                          - Windows.old (10-30 GB)                     ║" -ForegroundColor Gray
        Write-Host "    ║                          - Hibernacion OFF (RAM)                      ║" -ForegroundColor Gray
        Write-Host "    ║                          - Logs de eventos                            ║" -ForegroundColor Gray
        Write-Host "    ║                          - Volcados de memoria                        ║" -ForegroundColor Gray
        Write-Host "    ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "    ║  [S] Saltar y terminar                                                ║" -ForegroundColor DarkGray
        Write-Host "    ║  [X] Salir                                                            ║" -ForegroundColor DarkGray
        Write-Host "    ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "    ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "    Opcion: " -NoNewline -ForegroundColor Yellow
        $opExtra = Read-Host

        if ($opExtra.ToUpper() -eq "X") { [Environment]::Exit(0) }

        switch ($opExtra.ToUpper()) {
            "D" {
                Write-Host ""
                Write-Host "    Ejecutando DISM + SFC (puede tardar 15-30 minutos)..." -ForegroundColor Cyan
                Write-Host "    No cierres esta ventana." -ForegroundColor Yellow
                Write-Host ""
                Repair-WindowsHealth
                Add-TaskResult -Nombre "DISM + SFC" -Estado "OK"
            }
            "P" {
                Write-Host ""
                Write-Host "    ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
                Write-Host "    ║  [!] LIMPIEZA PROFUNDA - Esto es permanente                           ║" -ForegroundColor Red
                Write-Host "    ║  Escriba LIMPIAR para confirmar o cualquier tecla para cancelar       ║" -ForegroundColor Yellow
                Write-Host "    ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
                Write-Host ""
                Write-Host "    Confirmar: " -NoNewline -ForegroundColor Red
                $confirmProfunda = Read-Host

                if ($confirmProfunda -eq "LIMPIAR") {
                    Write-Host ""
                    Write-Host "    Ejecutando limpieza profunda..." -ForegroundColor Cyan

                    Write-Host "    [1/6] Windows.old..." -ForegroundColor White
                    $r1 = Clear-WindowsOld
                    $script:Stats.TotalLiberado += $r1.Liberado
                    Add-TaskResult -Nombre "Windows.old" -Estado $(if($r1.Exito){"OK"}else{"SKIP"}) -BytesLiberados $r1.Liberado

                    Write-Host "    [2/6] Hibernacion OFF..." -ForegroundColor White
                    $r2 = Disable-Hibernation
                    $script:Stats.TotalLiberado += $r2.Liberado
                    Add-TaskResult -Nombre "Hibernacion" -Estado $(if($r2.Exito){"OK"}else{"SKIP"}) -BytesLiberados $r2.Liberado

                    Write-Host "    [3/6] WinSxS componentes..." -ForegroundColor White
                    $r3 = Clear-WinSxS
                    $script:Stats.TotalLiberado += $r3.Liberado
                    Add-TaskResult -Nombre "WinSxS" -Estado $(if($r3.Exito){"OK"}else{"SKIP"}) -BytesLiberados $r3.Liberado

                    Write-Host "    [4/6] Logs de eventos..." -ForegroundColor White
                    $r4 = Clear-EventLogs
                    $script:Stats.TotalLiberado += $r4.Liberado
                    Add-TaskResult -Nombre "Event Logs" -Estado $(if($r4.Exito){"OK"}else{"SKIP"}) -BytesLiberados $r4.Liberado

                    Write-Host "    [5/6] Volcados de memoria..." -ForegroundColor White
                    $r5 = Clear-MemoryDumps
                    $script:Stats.TotalLiberado += $r5.Liberado
                    Add-TaskResult -Nombre "Memory Dumps" -Estado $(if($r5.Exito){"OK"}else{"SKIP"}) -BytesLiberados $r5.Liberado

                    Write-Host "    [6/6] Delivery Optimization..." -ForegroundColor White
                    $r6 = Clear-DeliveryOptimization
                    $script:Stats.TotalLiberado += $r6.Liberado
                    Add-TaskResult -Nombre "Delivery Opt" -Estado $(if($r6.Exito){"OK"}else{"SKIP"}) -BytesLiberados $r6.Liberado

                    Write-Host ""
                    Write-Host "    [OK] Limpieza profunda completada" -ForegroundColor Cyan
                } else {
                    Write-Host "    Limpieza profunda cancelada" -ForegroundColor Yellow
                    Add-TaskResult -Nombre "Limpieza Profunda" -Estado "SKIP"
                }
            }
            default {
                Add-TaskResult -Nombre "Opciones extra" -Estado "SKIP"
            }
        }
    }

    # Capturar espacio libre DESPUES
    $script:Stats.BytesDespues = Get-DiscoLibre

    # Generar reportes
    Show-FregonatorResumen
    Show-Comparativa
    $htmlPath = Export-FregonatorHTML
    Complete-FregonatorLog

    # Guardar en historial
    $duracion = (Get-Date) - $script:Stats.StartTime
    $totalBytes = ($script:TaskResults | ForEach-Object { $_.BytesLiberados } | Measure-Object -Sum).Sum
    Add-LimpiezaHistorial -Modo "Avanzada" -BytesLiberados $totalBytes -Tareas $script:TaskResults.Count -Duracion $duracion

    # Notificacion Windows
    $totalMB = [math]::Round($totalBytes / 1MB, 0)
    Update-Monitor -Etapa "Completado" -Progreso 100 -EspacioMB $totalMB -Log "Limpieza finalizada: $totalMB MB liberados" -Terminado

    # En modo GUI: terminar limpiamente sin menus
    if ($script:ModoGUI) {
        return
    }

    Show-WindowsNotification -Titulo (T 'notificacionTitulo') -Mensaje "$(T 'limpiezaFinalizada'): $totalMB MB $(T 'espacioLiberado')"

    Write-Host ""
    Write-Host "    ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║  [H] Abrir informe HTML    [L] Abrir carpeta logs                     ║" -ForegroundColor White
    Write-Host "    ║  [V] Volver al menu        [X] Salir                                  ║" -ForegroundColor Gray
    Write-Host "    ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Opcion: " -NoNewline -ForegroundColor Yellow

    $opcion = Read-Host
    switch ($opcion.ToUpper()) {
        "H" { if (Test-Path $htmlPath) { Start-Process $htmlPath } }
        "L" { Start-Process explorer.exe -ArgumentList $script:CONFIG.LogPath }
        "X" { [Environment]::Exit(0) }
    }
}

# =============================================================================
# AVANZADO - Elegir que hacer (LEGACY - ya no se usa en menu principal)
# =============================================================================

function Start-Avanzado {
    while ($true) {
        $opcionesAvz = @(
            @{ Key = "1"; Label = "Liberar RAM"; Description = "Ejecuta GC" }
            @{ Key = "2"; Label = "Limpiar temporales"; Description = "Cache y temp" }
            @{ Key = "3"; Label = "Vaciar papelera"; Description = "Recycle Bin" }
            @{ Key = "4"; Label = "Limpiar cache DNS"; Description = "ipconfig /flushdns" }
            @{ Key = "5"; Label = "Optimizar discos"; Description = "Defrag SSD/HDD" }
            @{ Key = "6"; Label = "Alto Rendimiento"; Description = "Plan energia" }
            @{ Key = "7"; Label = "Actualizar apps"; Description = "winget upgrade" }
            @{ Key = "8"; Label = "Windows Update"; Description = "Buscar updates" }
            @{ Key = "9"; Label = "Eliminar bloatware"; Description = "Apps basura" }
            @{ Key = "R"; Label = "Punto restauracion"; Description = "Crear backup" }
            @{ Key = "-"; Label = ""; Disabled = $true }
            @{ Key = "T"; Label = "TUNING TOTAL"; Description = "Registro+Procesos+CPU"; Recommended = $true }
            @{ Key = "D"; Label = "DISM + SFC"; Description = "Reparar Windows" }
            @{ Key = "S"; Label = "Desactivar telemetria"; Description = "DiagTrack OFF" }
            @{ Key = "E"; Label = "Efectos visuales"; Description = "Modo rendimiento" }
            @{ Key = "-"; Label = ""; Disabled = $true }
            @{ Key = "P"; Label = "PatchMyPC"; Description = "+500 apps" }
            @{ Key = "-"; Label = ""; Disabled = $true }
            @{ Key = "L"; Label = "Ver logs"; Description = "Carpeta" }
            @{ Key = "-"; Label = ""; Disabled = $true }
            @{ Key = "V"; Label = "Volver"; Description = "Menu principal" }
            @{ Key = "X"; Label = "Salir"; Description = "" }
        )

        $op = Show-MenuInteractivo -Titulo "OPCIONES AVANZADAS" -Opciones $opcionesAvz -LogoFunction { Show-Logo -Subtitulo "MODO AVANZADO" }

        switch ($op.ToUpper()) {
            "1" {
                Write-Host "    Liberando RAM..." -ForegroundColor Cyan
                Clear-RAM
                Write-Host "    [OK] RAM liberada" -ForegroundColor Cyan
                Start-Sleep 1
            }
            "2" {
                Write-Host "    Limpiando temporales..." -ForegroundColor Cyan
                $l = Clear-TempFiles
                Write-Host "    [OK] $([math]::Round($l/1MB,0)) MB liberados" -ForegroundColor Cyan
                Read-Host "    ENTER para volver"
            }
            "3" {
                Write-Host "    Vaciando papelera..." -ForegroundColor Cyan
                Clear-RecycleBinSafe
                Write-Host "    [OK] Papelera vacia" -ForegroundColor Cyan
                Start-Sleep 1
            }
            "4" {
                Write-Host "    Limpiando cache DNS..." -ForegroundColor Cyan
                Clear-DNSCache
                Write-Host "    [OK] Cache DNS limpiado" -ForegroundColor Cyan
                Start-Sleep 1
            }
            "5" {
                Write-Host "    Optimizando discos..." -ForegroundColor Cyan
                Optimize-Disks
                Write-Host "    [OK] Discos optimizados" -ForegroundColor Cyan
                Read-Host "    ENTER para volver"
            }
            "6" {
                Write-Host "    Activando Alto Rendimiento..." -ForegroundColor Cyan
                Set-HighPerformance
                Write-Host "    [OK] Plan de energia cambiado" -ForegroundColor Cyan
                Start-Sleep 1
            }
            "7" {
                Write-Host "    Actualizando apps con winget..." -ForegroundColor Cyan
                Update-Apps
                Write-Host "    [OK] Apps actualizadas" -ForegroundColor Cyan
                Read-Host "    ENTER para volver"
            }
            "8" {
                Write-Host "    Iniciando Windows Update..." -ForegroundColor Cyan
                Update-Windows
                Write-Host "    [OK] Windows Update iniciado" -ForegroundColor Cyan
                Start-Sleep 1
            }
            "9" {
                Write-Host "    Eliminando bloatware..." -ForegroundColor Cyan
                $n = Remove-Bloatware
                Write-Host "    [OK] $n apps eliminadas" -ForegroundColor Cyan
                Read-Host "    ENTER para volver"
            }
            "R" {
                Write-Host "    Creando punto de restauracion..." -ForegroundColor Cyan
                New-RestorePoint
                Write-Host "    [OK] Punto creado" -ForegroundColor Cyan
                Read-Host "    ENTER para volver"
            }
            "T" {
                # TUNING TOTAL - Todo junto
                Start-FregonatorLog -Operation "TUNING-TOTAL"
                Write-Host ""
                Write-Host "    TUNING TOTAL - Optimizacion completa" -ForegroundColor Cyan
                Write-Host "    ──────────────────────────────────────" -ForegroundColor DarkGray
                Write-Host ""

                Write-Host "    [1/6] Limpiando registro MRU..." -ForegroundColor White
                $mru = Clear-RegistryMRU
                Write-Host "        [OK] $mru entradas limpiadas" -ForegroundColor Cyan

                Write-Host "    [2/6] Cerrando procesos innecesarios..." -ForegroundColor White
                $procs = Stop-UnnecessaryProcesses
                Write-Host "        [OK] $($procs.Cerrados) procesos ($($procs.RAMMb) MB)" -ForegroundColor Cyan

                Write-Host "    [3/6] Optimizando CPU..." -ForegroundColor White
                Optimize-CPUPerformance | Out-Null
                Write-Host "        [OK] CPU al 100%, core parking OFF" -ForegroundColor Cyan

                Write-Host "    [4/6] Limpiando cache ARP..." -ForegroundColor White
                Clear-ARPCache | Out-Null
                Write-Host "        [OK] Cache ARP limpiado" -ForegroundColor Cyan

                Write-Host "    [5/6] Desactivando telemetria..." -ForegroundColor White
                $tel = Disable-TelemetryServices
                Write-Host "        [OK] $tel servicios desactivados" -ForegroundColor Cyan

                Write-Host "    [6/6] Optimizando efectos visuales..." -ForegroundColor White
                Optimize-VisualEffects | Out-Null
                Write-Host "        [OK] Modo rendimiento activado" -ForegroundColor Cyan

                Write-Host ""
                Write-Host "    ══════════════════════════════════════" -ForegroundColor Cyan
                Write-Host "    TUNING TOTAL COMPLETADO" -ForegroundColor Cyan
                Write-Host "    ══════════════════════════════════════" -ForegroundColor Cyan
                Write-Host ""
                Read-Host "    ENTER para volver"
            }
            "D" {
                Write-Host ""
                Write-Host "    REPARAR WINDOWS (DISM + SFC)" -ForegroundColor Cyan
                Write-Host "    Esto puede tardar 15-30 minutos..." -ForegroundColor Yellow
                Write-Host ""
                $r = Repair-WindowsHealth
                Write-Host ""
                if ($r.DISM -and $r.SFC) {
                    Write-Host "    [OK] $($r.Mensaje)" -ForegroundColor Cyan
                } else {
                    Write-Host "    [!] $($r.Mensaje)" -ForegroundColor Yellow
                }
                Read-Host "    ENTER para volver"
            }
            "S" {
                Write-Host "    Desactivando servicios de telemetria..." -ForegroundColor Cyan
                $n = Disable-TelemetryServices
                Write-Host "    [OK] $n servicios desactivados (DiagTrack, WAP, SysMain)" -ForegroundColor Cyan
                Read-Host "    ENTER para volver"
            }
            "E" {
                Write-Host "    Optimizando efectos visuales..." -ForegroundColor Cyan
                Optimize-VisualEffects | Out-Null
                Write-Host "    [OK] Efectos visuales: Modo rendimiento" -ForegroundColor Cyan
                Start-Sleep 1
            }
            "P" { Start-PatchMyPC; Read-Host "    ENTER para volver" }
            "L" {
                if (Test-Path $script:CONFIG.LogPath) {
                    Start-Process explorer.exe $script:CONFIG.LogPath
                } else {
                    Write-Host "    No hay logs todavia" -ForegroundColor Yellow
                    Start-Sleep 1
                }
            }
            "X" { return "exit" }
            "V" { return }
        }
    }
}

# =============================================================================
# MENU PRINCIPAL - Simplificado a 2 opciones
# =============================================================================

# Splash de Nala al inicio
Show-NalaSplash

# Refrescar fondo gris para el menu
Set-FondoOscuro

function Show-MenuPrincipal {
    param([int]$Selected = 1)

    Show-Logo

    # Info compacta: solo disco y RAM (una linea)
    $info = Get-PCInfo
    $disco = if ($info.Disco) { $info.Disco -replace 'C: ', '' } else { "N/A" }
    $ram = if ($info.RAM) { $info.RAM } else { "N/A" }
    Write-Host "    C:\ $disco   |   RAM: $ram" -ForegroundColor DarkGray
    Write-Host ""

    # Flechas para indicar seleccion
    $arrow = [char]0x25BA  # ►
    $arrowL = [char]0x25C4  # ◄

    Write-Host "    ╔════════════════════════════════════╦════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║                                    ║                                    ║" -ForegroundColor Cyan

    # Fila de titulos con seleccion visual (cada celda = 36 chars, linea total = 79 chars)
    # Texto1 con flechas = 21 chars, Texto2 = 21 chars
    if ($Selected -eq 1) {
        # Col1: ►[1] LIMPIEZA RAPIDA◄ (21) + 15 espacios = 36
        # Col2:  [2] LIMPIEZA AVANZADA (22) + 14 espacios = 36
        Write-Host "    ║" -NoNewline -ForegroundColor Cyan
        Write-Host "$arrow" -NoNewline -ForegroundColor Yellow
        Write-Host "[1] LIMPIEZA RAPIDA" -NoNewline -ForegroundColor Black -BackgroundColor DarkYellow
        Write-Host "$arrowL" -NoNewline -ForegroundColor Yellow
        Write-Host "               ║" -NoNewline -ForegroundColor Cyan
        Write-Host " [2] LIMPIEZA AVANZADA              ║" -ForegroundColor Gray
    } else {
        # Col1:  [1] LIMPIEZA RAPIDA (20) + 16 espacios = 36
        # Col2: ►[2] LIMPIEZA AVANZADA◄ (23) + 13 espacios = 36
        Write-Host "    ║ [1] LIMPIEZA RAPIDA                ║" -NoNewline -ForegroundColor Gray
        Write-Host "$arrow" -NoNewline -ForegroundColor Yellow
        Write-Host "[2] LIMPIEZA AVANZADA" -NoNewline -ForegroundColor Black -BackgroundColor DarkYellow
        Write-Host "$arrowL" -NoNewline -ForegroundColor Yellow
        Write-Host "             ║" -ForegroundColor Cyan
    }

    Write-Host "    ╟────────────────────────────────────╫────────────────────────────────────╢" -ForegroundColor Cyan
    Write-Host "    ║      8 tareas en paralelo          ║      13 tareas + opciones          ║" -ForegroundColor Gray
    Write-Host "    ║      ~30 segundos                  ║      + DISM/SFC opcional           ║" -ForegroundColor Gray
    Write-Host "    ║                                    ║      + Limpieza profunda           ║" -ForegroundColor Gray
    Write-Host "    ╟────────────────────────────────────╫────────────────────────────────────╢" -ForegroundColor Cyan
    Write-Host "    ║  - Liberar RAM                     ║  - Todo lo de Rapida               ║" -ForegroundColor DarkGray
    Write-Host "    ║  - Limpiar temporales              ║  - Eliminar bloatware              ║" -ForegroundColor DarkGray
    Write-Host "    ║  - Vaciar papelera                 ║  - Telemetria OFF                  ║" -ForegroundColor DarkGray
    Write-Host "    ║  - Cache DNS                       ║  - Registro MRU                    ║" -ForegroundColor DarkGray
    Write-Host "    ║  - Optimizar discos                ║  - Matar procesos                  ║" -ForegroundColor DarkGray
    Write-Host "    ║  - Alto rendimiento                ║  - Efectos visuales                ║" -ForegroundColor DarkGray
    Write-Host "    ║  - Actualizar apps                 ║                                    ║" -ForegroundColor DarkGray
    Write-Host "    ║  - Windows Update                  ║  Al final puedes elegir:           ║" -ForegroundColor DarkGray
    Write-Host "    ║                                    ║  [D] DISM+SFC (reparar)            ║" -ForegroundColor DarkGray
    Write-Host "    ║                                    ║  [P] Profunda (5-50 GB)            ║" -ForegroundColor DarkGray
    Write-Host "    ╠════════════════════════════════════╩════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "    ║  [A] Desinstalar apps   [S] Apps arranque   [R] Rendimiento  [X] Salir  ║" -ForegroundColor Gray
    Write-Host "    ║  [D] Drivers            [P] Programar       [H] Historial    [L] Logs   ║" -ForegroundColor DarkGray
    Write-Host "    ╚═════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    $upArrow = [char]0x2190  # ←
    $downArrow = [char]0x2192  # →
    Write-Host "    $upArrow$downArrow Mover   ENTER Ejecutar   [1][2][A][S][R][D][P][H][L][X] Atajo" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "    Opcion: " -NoNewline -ForegroundColor Yellow
}

# =============================================================================
# MODO AUTO UI - Ejecutar con UI completa desde launcher (barras, colores, etc)
# =============================================================================
if ($AutoRapida) {
    Start-OneClick
    Write-Host ""
    Write-Host "    Cerrando en 3 segundos..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 3
    exit 0
}

if ($AutoAvanzada) {
    Start-OneClickAvanzada
    Write-Host ""
    Write-Host "    Cerrando en 3 segundos..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 3
    exit 0
}

# =============================================================================
# MODO SILENCIOSO - Ejecutar sin UI para scripts y automatizacion
# =============================================================================
if ($script:SilentMode) {
    # Modo silencioso: ejecutar y salir
    Write-Host ""
    Write-Host "  FREGONATOR v4.0 - Modo Silencioso" -ForegroundColor Cyan
    Write-Host "  =====================================" -ForegroundColor Cyan
    Write-Host ""

    $script:Stats.StartTime = Get-Date
    $script:TaskResults = @()

    if ($Avanzada) {
        Write-Host "  Ejecutando UN CLICK AVANZADA..." -ForegroundColor Yellow
        Start-FregonatorLog -Operation "SILENT-AVANZADA"

        # Tareas avanzadas en silencioso
        Write-Host "  [1/13] Liberando RAM..." -ForegroundColor Gray
        [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()
        Add-TaskResult -Nombre "Liberar RAM" -Estado "OK"

        Write-Host "  [2/13] Limpiando temporales..." -ForegroundColor Gray
        $temp = Clear-TempFiles -Silent
        Add-TaskResult -Nombre "Limpiar temporales" -Estado "OK" -BytesLiberados $temp

        Write-Host "  [3/13] Vaciando papelera..." -ForegroundColor Gray
        Clear-RecycleBinSafe
        Add-TaskResult -Nombre "Vaciar papelera" -Estado "OK"

        Write-Host "  [4/13] Limpiando cache DNS..." -ForegroundColor Gray
        Clear-DNSCache
        Add-TaskResult -Nombre "Cache DNS" -Estado "OK"

        Write-Host "  [5/13] Optimizando discos..." -ForegroundColor Gray
        Optimize-Disks -Silent
        Add-TaskResult -Nombre "Optimizar discos" -Estado "OK"

        Write-Host "  [6/13] Alto rendimiento..." -ForegroundColor Gray
        Set-HighPerformance
        Add-TaskResult -Nombre "Alto rendimiento" -Estado "OK"

        Write-Host "  [7/13] Actualizando apps..." -ForegroundColor Gray
        Update-Apps
        Add-TaskResult -Nombre "Actualizar apps" -Estado "OK"

        Write-Host "  [8/13] Windows Update..." -ForegroundColor Gray
        Update-Windows
        Add-TaskResult -Nombre "Windows Update" -Estado "OK"

        Write-Host "  [9/13] Eliminando bloatware..." -ForegroundColor Gray
        Remove-Bloatware | Out-Null
        Add-TaskResult -Nombre "Eliminar bloatware" -Estado "OK"

        Write-Host "  [10/13] Limpiando registro MRU..." -ForegroundColor Gray
        Clear-RegistryMRU | Out-Null
        Add-TaskResult -Nombre "Registro MRU" -Estado "OK"

        Write-Host "  [11/13] Cerrando procesos..." -ForegroundColor Gray
        Stop-UnnecessaryProcesses | Out-Null
        Add-TaskResult -Nombre "Cerrar procesos" -Estado "OK"

        Write-Host "  [12/13] Desactivando telemetria..." -ForegroundColor Gray
        Disable-TelemetryServices | Out-Null
        Add-TaskResult -Nombre "Telemetria OFF" -Estado "OK"

        Write-Host "  [13/13] Efectos visuales..." -ForegroundColor Gray
        Optimize-VisualEffects | Out-Null
        Add-TaskResult -Nombre "Efectos visuales" -Estado "OK"
    }
    else {
        Write-Host "  Ejecutando UN CLICK RAPIDA..." -ForegroundColor Yellow
        Start-FregonatorLog -Operation "SILENT-RAPIDA"

        # Tareas basicas en silencioso
        Write-Host "  [1/8] Liberando RAM..." -ForegroundColor Gray
        [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()
        Add-TaskResult -Nombre "Liberar RAM" -Estado "OK"

        Write-Host "  [2/8] Limpiando temporales..." -ForegroundColor Gray
        $temp = Clear-TempFiles -Silent
        Add-TaskResult -Nombre "Limpiar temporales" -Estado "OK" -BytesLiberados $temp

        Write-Host "  [3/8] Vaciando papelera..." -ForegroundColor Gray
        Clear-RecycleBinSafe
        Add-TaskResult -Nombre "Vaciar papelera" -Estado "OK"

        Write-Host "  [4/8] Limpiando cache DNS..." -ForegroundColor Gray
        Clear-DNSCache
        Add-TaskResult -Nombre "Cache DNS" -Estado "OK"

        Write-Host "  [5/8] Optimizando discos..." -ForegroundColor Gray
        Optimize-Disks -Silent
        Add-TaskResult -Nombre "Optimizar discos" -Estado "OK"

        Write-Host "  [6/8] Alto rendimiento..." -ForegroundColor Gray
        Set-HighPerformance
        Add-TaskResult -Nombre "Alto rendimiento" -Estado "OK"

        Write-Host "  [7/8] Actualizando apps..." -ForegroundColor Gray
        Update-Apps
        Add-TaskResult -Nombre "Actualizar apps" -Estado "OK"

        Write-Host "  [8/8] Windows Update..." -ForegroundColor Gray
        Update-Windows
        Add-TaskResult -Nombre "Windows Update" -Estado "OK"
    }

    # Resumen final silencioso
    Complete-FregonatorLog
    $duracion = (Get-Date) - $script:Stats.StartTime
    $totalBytes = ($script:TaskResults | ForEach-Object { $_.BytesLiberados } | Measure-Object -Sum).Sum
    $totalMB = [math]::Round($totalBytes / 1MB, 0)

    Write-Host ""
    Write-Host "  =====================================" -ForegroundColor Cyan
    Write-Host "  COMPLETADO en $([math]::Round($duracion.TotalSeconds))s | $totalMB MB liberados" -ForegroundColor Cyan
    Write-Host "  Log: $script:CurrentLogFile" -ForegroundColor DarkGray
    Write-Host "  =====================================" -ForegroundColor Cyan
    Write-Host ""

    exit 0
}

# =============================================================================
# MODO INTERACTIVO - Menu principal
# =============================================================================

# Verificar si estamos en consola interactiva
if (-not (Test-ConsolaInteractiva)) {
    Write-Host ""
    Write-Host "    [!] FREGONATOR requiere consola interactiva para modo menu." -ForegroundColor Red
    Write-Host "    [!] Usa -Silent o -Avanzada para ejecutar sin UI." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Ejemplo: .\Fregonator.ps1 -Silent" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

$selectedOption = 1
$needRedraw = $true

while ($true) {
    if ($needRedraw) {
        Clear-Host
        Show-MenuPrincipal -Selected $selectedOption
        $needRedraw = $false
    }

    # Leer tecla
    $key = [Console]::ReadKey($true)

    # Mostrar la tecla presionada (eco visual)
    if ($key.KeyChar -match '[0-9a-zA-Z]') {
        Write-Host $key.KeyChar.ToString().ToUpper() -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 150
    }

    switch ($key.Key) {
        "LeftArrow" {
            if ($selectedOption -ne 1) {
                $selectedOption = 1
                $needRedraw = $true
            }
        }
        "RightArrow" {
            if ($selectedOption -ne 2) {
                $selectedOption = 2
                $needRedraw = $true
            }
        }
        "Enter" {
            if ($selectedOption -eq 1) { Start-OneClick }
            else { Start-OneClickAvanzada }
            $needRedraw = $true
        }
        "D1" { Start-OneClick; $needRedraw = $true }
        "NumPad1" { Start-OneClick; $needRedraw = $true }
        "D2" { Start-OneClickAvanzada; $needRedraw = $true }
        "NumPad2" { Start-OneClickAvanzada; $needRedraw = $true }
        "A" { Start-Process "ms-settings:appsfeatures" }
        "S" { Start-Process "ms-settings:startupapps" }
        "R" { Start-Process "resmon.exe" }
        "D" {
            Show-DriverUpdater
            $needRedraw = $true
        }
        "L" {
            if (Test-Path $script:CONFIG.LogPath) {
                Start-Process explorer.exe $script:CONFIG.LogPath
            } else {
                Write-Host "    No hay logs todavia" -ForegroundColor Yellow
                Start-Sleep 1
                $needRedraw = $true
            }
        }
        "P" {
            Show-ProgramarLimpieza
            $needRedraw = $true
        }
        "H" {
            Show-LimpiezaHistorial
            $needRedraw = $true
        }
        "I" {
            Write-Host ""
            Write-Host "    ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "    ║                         IDIOMA / LANGUAGE                         ║" -ForegroundColor Cyan
            Write-Host "    ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
            Write-Host "    ║  [1] Español                                                      ║" -ForegroundColor White
            Write-Host "    ║  [2] English                                                      ║" -ForegroundColor White
            Write-Host "    ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "    Option / Opcion: " -NoNewline -ForegroundColor Yellow
            $idiomaOp = Read-Host
            switch ($idiomaOp) {
                "1" { $script:CONFIG.Idioma = "es"; Write-Host "    Idioma: Español" -ForegroundColor Green }
                "2" { $script:CONFIG.Idioma = "en"; Write-Host "    Language: English" -ForegroundColor Green }
            }
            Start-Sleep 1
            $needRedraw = $true
        }
        "T" {
            Show-ProgramarLimpieza
            $needRedraw = $true
        }
        "U" {
            $updateScript = "$PSScriptRoot\Fregonator-AutoUpdate.ps1"
            if (Test-Path $updateScript) {
                . $updateScript
                Invoke-UpdateCheck -Force
                Write-Host ""
                Write-Host "    ENTER para volver..." -ForegroundColor DarkGray
                Read-Host
            } else {
                Write-Host ""
                Write-Host "    [!] Auto-update no disponible" -ForegroundColor Yellow
                Start-Sleep 2
            }
            $needRedraw = $true
        }
        "X" {
            Write-Host ""
            Write-Host "    Hasta pronto!" -ForegroundColor Cyan
            Start-Sleep -Milliseconds 500
            [Environment]::Exit(0)
        }
        "Escape" {
            # ESC = Salir (igual que X)
            Write-Host ""
            Write-Host "    Hasta pronto!" -ForegroundColor Cyan
            Start-Sleep -Milliseconds 500
            [Environment]::Exit(0)
        }
    }
}
