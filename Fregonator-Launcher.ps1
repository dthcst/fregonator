<#
    FREGONATOR LAUNCHER v7.0
    Menu principal con efecto Glow + Sonidos
    - Oculto de barra de tareas
    2026
#>

# Ocultar ventana de consola del Launcher
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("User32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$null = [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Icono propio en barra de tareas (no el de PowerShell)
try {
    $appId = "fregonator.com"
    $shell32 = Add-Type -MemberDefinition '[DllImport("shell32.dll")] public static extern int SetCurrentProcessExplicitAppUserModelID([MarshalAs(UnmanagedType.LPWStr)] string AppID);' -Name Shell32AppId -Namespace Win32 -PassThru
    $shell32::SetCurrentProcessExplicitAppUserModelID($appId) | Out-Null
} catch {}

# ============================================================================
# SINGLETON - Solo una instancia del Launcher
# ============================================================================
# Matazombies: matar cualquier instancia anterior (incluidas ocultas en tray)
$myPid = $PID
Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
    $_.Id -ne $myPid -and ($_.MainWindowTitle -eq "FREGONATOR" -or $_.MainWindowTitle -eq "")
} | ForEach-Object {
    try {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        if ($cmdLine -and $cmdLine -match "Fregonator-Launcher") {
            $_.Kill()
        }
    } catch {}
}
Start-Sleep -Milliseconds 300
$script:FregMutex = New-Object System.Threading.Mutex($false, "Global\FREGONATOR_LAUNCHER_v6")
if (-not $script:FregMutex.WaitOne(0)) {
    # Si sigue ocupado, matar todo por fuerza
    Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $myPid } | ForEach-Object {
        try {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmdLine -and $cmdLine -match "Fregonator-Launcher") { $_.Kill() }
        } catch {}
    }
    Start-Sleep -Milliseconds 500
    $script:FregMutex = New-Object System.Threading.Mutex($false, "Global\FREGONATOR_LAUNCHER_v6")
    $null = $script:FregMutex.WaitOne(2000)
}

# ============================================================================
# RUTAS (scope script para acceso en eventos)
# ============================================================================
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:FregonatorScript = Join-Path $script:ScriptPath "Fregonator.ps1"
$script:MonitorScript = Join-Path $script:ScriptPath "Fregonator-Monitor.ps1"
$script:LogoPath = Join-Path $script:ScriptPath "Logo-Fregonator-001.png"
$script:FontPath = Join-Path $script:ScriptPath "_FUENTES\citaro_voor_dubbele_hoogte_breed\citaro_voor_dubbele_hoogte_breed.ttf"
$script:ProgressFile = "$env:PUBLIC\fregonator_progress.json"
$script:BarkSound = Join-Path $script:ScriptPath "sounds\bark.wav"

# ============================================================================
# IDIOMA - Preferencia guardada > Deteccion automatica
# ============================================================================
function Get-SystemLanguage {
    # Primero verificar preferencia guardada
    $configFile = "$env:LOCALAPPDATA\FREGONATOR\lang.txt"
    if (Test-Path $configFile) {
        $saved = (Get-Content $configFile -Raw).Trim()
        if ($saved -eq "en" -or $saved -eq "es" -or $saved -eq "gl") { return $saved }
    }

    # Auto-detectar del sistema
    $uiCulture = (Get-UICulture).Name
    $culture = (Get-Culture).Name
    foreach ($lang in @($uiCulture, $culture)) {
        if ($lang -like "en*") { return "en" }
        if ($lang -like "gl*") { return "gl" }
        if ($lang -like "es*") { return "es" }
    }
    return "en"  # Default internacional
}

$script:Lang = Get-SystemLanguage

$script:Texts = @{
    es = @{
        v7Frase       = "Tu PC, limpio."
        v7Ultra       = "ULTRA"
        v7Nota        = "Básica: lo justo. Avanzada: a fondo. Ultra: además actualiza tus programas."
        v7Sub1        = "Un botón y ya está. Sin cuentas, sin comandos, sin decidir nada."
        v7Sub2        = "Sin anuncios, sin telemetría, sin versión de pago."
        v7Tranqui     = "Tranquilo: no toca nada importante de tu PC."
        v7Tranqui2    = "Ni tus fotos, ni tus contraseñas, ni tus programas."
        v7Sello       = "ABUELO-PROOF"
        v7Basica      = "LIMPIEZA BÁSICA"
        v7BasicaSub   = "Lo de siempre. 8 tareas, unos 30 segundos."
        v7Avanzada    = "LIMPIEZA AVANZADA"
        v7AvanzadaSub = "A fondo. 13 tareas, tarda un poco mas."
        v7Terminal    = "TERMINAL MS-DOS"
        v7Salir       = "SALIR"
        limpiezaRapida = "LIMPIEZA RAPIDA"
        limpiezaCompleta = "LIMPIEZA COMPLETA"
        terminal = "TERMINAL MS-DOS"
        salir = "SALIR"
        descRapida = "Temporales, cache, papelera, RAM (8 tareas)"
        descCompleta = "Todo + bloatware, telemetria, optimizacion (13 tareas)"
        descTerminal = "Interfaz clasica con todas las opciones"
        programar = "PROGRAMAR LIMPIEZA"
        frecuencia = "Frecuencia:"
        diaria = "Diaria (medianoche)"
        semanal = "Semanal (domingos)"
        inicioSesion = "Al iniciar sesion"
        activar = "ACTIVAR"
        cancelar = "CANCELAR"
        infoLimpieza = "La limpieza se ejecutara en segundo plano`nusando el modo silencioso (sin ventanas)."
        version = "v7.0 - 31/07/2026"
        minimizadoBandeja = "Minimizado a la bandeja"
        abrirFregonator = "Abrir FREGONATOR"
        optimizadorPC = "OPTIMIZADOR DE PC"
        estado = "Estado"
        hora = "Hora:"
        recomendado = "recomendado"
        desactivar = "DESACTIVAR"
        cerrar = "CERRAR"
        tareaProgramadaCreada = "Tarea programada creada correctamente."
        frecuenciaLabel = "Frecuencia"
        horaLabel = "Hora"
        errorAdmin = "Error: Ejecuta FREGONATOR como Administrador."
        tareaProgramadaEliminada = "Tarea programada eliminada."
        noTareaProgramada = "No hay tarea programada activa."
        activo = "ACTIVO"
        noConfigurado = "NO CONFIGURADO"
        proxima = "Proxima"
        programarLimpieza = "PROGRAMAR LIMPIEZA"
        diariaRecomendado = "Diaria (recomendado)"
        alIniciarSesion = "Al iniciar sesion"
    }
    en = @{
        v7Frase       = "Your PC, clean."
        v7Ultra       = "ULTRA"
        v7Nota        = "Basic: the essentials. Deep: thorough. Ultra: also updates your apps."
        v7Sub1        = "One button and you are done. No accounts, no commands, nothing to decide."
        v7Sub2        = "No ads, no telemetry, no paid version."
        v7Tranqui     = "Relax: it never touches anything that matters on your PC."
        v7Tranqui2    = "Not your photos, not your passwords, not your programs."
        v7Sello       = "GRANDPA-PROOF"
        v7Basica      = "BASIC CLEAN"
        v7BasicaSub   = "The usual. 8 tasks, about 30 seconds."
        v7Avanzada    = "DEEP CLEAN"
        v7AvanzadaSub = "The full thing. 13 tasks, takes a bit longer."
        v7Terminal    = "MS-DOS TERMINAL"
        v7Salir       = "EXIT"
        limpiezaRapida = "QUICK CLEANUP"
        limpiezaCompleta = "FULL CLEANUP"
        terminal = "TERMINAL MS-DOS"
        salir = "EXIT"
        descRapida = "Temp files, cache, recycle bin, RAM (8 tasks)"
        descCompleta = "All + bloatware, telemetry, optimization (13 tasks)"
        descTerminal = "Classic interface with all options"
        programar = "SCHEDULE CLEANUP"
        frecuencia = "Frequency:"
        diaria = "Daily (midnight)"
        semanal = "Weekly (Sundays)"
        inicioSesion = "On login"
        activar = "ACTIVATE"
        cancelar = "CANCEL"
        infoLimpieza = "Cleanup will run in the background`nusing silent mode (no windows)."
        version = "v7.0 - 31/07/2026"
        minimizadoBandeja = "Minimized to tray"
        abrirFregonator = "Open FREGONATOR"
        optimizadorPC = "PC OPTIMIZER"
        estado = "Status"
        hora = "Time:"
        recomendado = "recommended"
        desactivar = "DEACTIVATE"
        cerrar = "CLOSE"
        tareaProgramadaCreada = "Scheduled task created successfully."
        frecuenciaLabel = "Frequency"
        horaLabel = "Time"
        errorAdmin = "Error: Run FREGONATOR as Administrator."
        tareaProgramadaEliminada = "Scheduled task removed."
        noTareaProgramada = "No active scheduled task."
        activo = "ACTIVE"
        noConfigurado = "NOT CONFIGURED"
        proxima = "Next"
        programarLimpieza = "SCHEDULE CLEANUP"
        diariaRecomendado = "Daily (recommended)"
        alIniciarSesion = "On login"
    }
    gl = @{
        v7Frase       = "O teu PC, limpo."
        v7Ultra       = "ULTRA"
        v7Nota        = "Básica: o xusto. Avanzada: a fondo. Ultra: ademais actualiza os teus programas."
        v7Sub1        = "Un botón e xa está. Sen contas, sen comandos, sen decidir nada."
        v7Sub2        = "Sen anuncios, sen telemetría, sen versión de pago."
        v7Tranqui     = "Tranquilo: non toca nada importante do teu PC."
        v7Tranqui2    = "Nin as túas fotos, nin os teus contrasinais, nin os teus programas."
        v7Sello       = "AVOO-PROOF"
        v7Basica      = "LIMPEZA BÁSICA"
        v7BasicaSub   = "O de sempre. 8 tarefas, uns 30 segundos."
        v7Avanzada    = "LIMPEZA AVANZADA"
        v7AvanzadaSub = "A fondo. 13 tarefas, tarda un pouco mais."
        v7Terminal    = "TERMINAL MS-DOS"
        v7Salir       = "SAIR"
        limpiezaRapida = "LIMPEZA RAPIDA"
        limpiezaCompleta = "LIMPEZA COMPLETA"
        terminal = "TERMINAL MS-DOS"
        salir = "SAIR"
        descRapida = "Temporais, cache, papeleira, RAM (8 tarefas)"
        descCompleta = "Todo + bloatware, telemetría, optimización (13 tarefas)"
        descTerminal = "Interface clásica con todas as opcións"
        programar = "PROGRAMAR LIMPEZA"
        frecuencia = "Frecuencia:"
        diaria = "Diaria (medianoite)"
        semanal = "Semanal (domingos)"
        inicioSesion = "Ao iniciar sesión"
        activar = "ACTIVAR"
        cancelar = "CANCELAR"
        infoLimpieza = "A limpeza executarase en segundo plano`nusando o modo silencioso (sen ventás)."
        version = "v7.0 - 31/07/2026"
        minimizadoBandeja = "Minimizado á bandexa"
        abrirFregonator = "Abrir FREGONATOR"
        optimizadorPC = "OPTIMIZADOR DE PC"
        estado = "Estado"
        hora = "Hora:"
        recomendado = "recomendado"
        desactivar = "DESACTIVAR"
        cerrar = "PECHAR"
        tareaProgramadaCreada = "Tarefa programada creada correctamente."
        frecuenciaLabel = "Frecuencia"
        horaLabel = "Hora"
        errorAdmin = "Erro: Executa FREGONATOR como Administrador."
        tareaProgramadaEliminada = "Tarefa programada eliminada."
        noTareaProgramada = "Non hai tarefa programada activa."
        activo = "ACTIVO"
        noConfigurado = "NON CONFIGURADO"
        proxima = "Próxima"
        programarLimpieza = "PROGRAMAR LIMPEZA"
        diariaRecomendado = "Diaria (recomendado)"
        alIniciarSesion = "Ao iniciar sesión"
    }
}

function Get-Text($key) {
    if ($script:Texts[$script:Lang] -and $script:Texts[$script:Lang][$key]) {
        return $script:Texts[$script:Lang][$key]
    }
    return $script:Texts["en"][$key]
}

# ============================================================================
# SONIDOS - Ladrido de Nala + Swoosh fregona-sable
# ============================================================================
$script:SoundEnabled = $true  # Toggle para activar/desactivar sonidos

$script:SoundPlayer = $null
if (Test-Path $script:BarkSound) {
    $script:SoundPlayer = New-Object System.Media.SoundPlayer($script:BarkSound)
}

# Funcion para reproducir ladrido (respeta toggle)
function Play-Bark {
    # v7: sin sonidos (decision CEO 31/07/2026)
}

# Funcion para sonido hover tipo "fregona-sable" (swoosh ascendente)
function Play-HoverSound {
    # v7: sin sonidos (decision CEO 31/07/2026)
}

# ============================================================================
# CARGAR FUENTES (scope script)
# ============================================================================
$script:privateFonts = New-Object System.Drawing.Text.PrivateFontCollection

# Citaro (botones, titulos)
if (Test-Path $script:FontPath) {
    $script:privateFonts.AddFontFile($script:FontPath)
    $script:citaroFamily = $script:privateFonts.Families[0]
} else {
    $script:citaroFamily = [System.Drawing.FontFamily]::GenericMonospace
}

# SAM font (header futurista)
$script:SamFontPath = Join-Path $script:ScriptPath "_FUENTES\SAM_5C_27TRG_.TTF"
if (Test-Path $script:SamFontPath) {
    $script:privateFonts.AddFontFile($script:SamFontPath)
    # SAM sera la ultima familia cargada
    $script:samFamily = $script:privateFonts.Families | Where-Object { $_.Name -ne $script:citaroFamily.Name } | Select-Object -First 1
    if (-not $script:samFamily) { $script:samFamily = $script:citaroFamily }
} else {
    $script:samFamily = $script:citaroFamily
}

# ============================================================================
# COLORES - Paleta v7: negro memmem + acento ambar
# ============================================================================
$script:ColFondo       = [System.Drawing.Color]::FromArgb(255, 255, 255)
$script:ColBoton       = [System.Drawing.Color]::FromArgb(255, 255, 255)
$script:ColCyan        = [System.Drawing.Color]::FromArgb(17, 17, 17)
$script:ColCyanBright  = [System.Drawing.Color]::FromArgb(0, 0, 0)
$script:ColCyanDark    = [System.Drawing.Color]::FromArgb(60, 60, 60)
$script:ColCyanDim     = [System.Drawing.Color]::FromArgb(110, 110, 110)
$script:ColGris        = [System.Drawing.Color]::FromArgb(110, 110, 110)
$script:ColNegro       = [System.Drawing.Color]::FromArgb(17, 17, 17)
$script:ColRojo        = [System.Drawing.Color]::FromArgb(200, 50, 50)
$script:ColVerde       = [System.Drawing.Color]::FromArgb(30, 150, 80)
$script:ColGlow        = [System.Drawing.Color]::FromArgb(0, 255, 255, 255)
$script:ColBorder      = [System.Drawing.Color]::FromArgb(210, 210, 210)
$script:ColBorderHover = [System.Drawing.Color]::FromArgb(17, 17, 17)
$script:ColPanelHover  = [System.Drawing.Color]::FromArgb(245, 245, 245)
$script:ColGridLine    = [System.Drawing.Color]::FromArgb(235, 235, 235)

# ============================================================================
# VENTANA PRINCIPAL - Centrada manualmente
# ============================================================================
$formWidth = 620
$formHeight = 500

$form = New-Object System.Windows.Forms.Form
$form.Text = "FREGONATOR"
$form.Size = New-Object System.Drawing.Size($formWidth, $formHeight)
$form.BackColor = $script:ColFondo
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$iconPath = Join-Path $script:ScriptPath "fregonator.ico"
if (Test-Path $iconPath) { $form.Icon = New-Object System.Drawing.Icon($iconPath) }

# --- SYSTRAY: minimizar a bandeja ---
$script:TrayIcon = New-Object System.Windows.Forms.NotifyIcon
$script:TrayIcon.Text = "Fregonator - www.costa-da-morte.com"
if (Test-Path $iconPath) { $script:TrayIcon.Icon = New-Object System.Drawing.Icon($iconPath) }
$script:TrayIcon.Visible = $false
$script:RealClose = $false
$script:TrayIcon.Add_DoubleClick({
    $form.Show()
    $form.WindowState = "Normal"
    $form.Activate()
    $script:TrayIcon.Visible = $false
})
# Context menu en tray: Abrir / Salir
$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$trayOpen = $trayMenu.Items.Add((Get-Text "abrirFregonator"))
$trayOpen.Add_Click({
    $form.Show()
    $form.WindowState = "Normal"
    $form.Activate()
    $script:TrayIcon.Visible = $false
})
$trayExit = $trayMenu.Items.Add((Get-Text "salir"))
$trayExit.Add_Click({
    $script:RealClose = $true
    $script:TrayIcon.Visible = $false
    $script:TrayIcon.Dispose()
    $form.Close()
})
$script:TrayIcon.ContextMenuStrip = $trayMenu
# X (cerrar) = mandar al tray en vez de cerrar
$form.Add_FormClosing({
    if (-not $script:RealClose) {
        $_.Cancel = $true
        $form.WindowState = "Minimized"
        $form.Hide()
        $script:TrayIcon.Visible = $true
        $script:TrayIcon.BalloonTipTitle = "Fregonator"
        $script:TrayIcon.BalloonTipText = (Get-Text "minimizadoBandeja")
        $script:TrayIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::None
        $script:TrayIcon.ShowBalloonTip(2000)
    }
})

# Centrar manualmente en pantalla
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.StartPosition = "CenterScreen"
$form.Location = New-Object System.Drawing.Point(
    [int](($screen.Width - $formWidth) / 2),
    [int](($screen.Height - $formHeight) / 2)
)

# ============================================================================
# HEADER - Texto futurista SAM font + iconos integrados
# ============================================================================
# Logo de la cabecera: Eustaquio bebe. Si falta, la app sigue igual.
$script:LogoImg = $null
try {
    $rutaLogo = Join-Path $PSScriptRoot "Logo-Fregonator-v7.png"
    if (Test-Path $rutaLogo) { $script:LogoImg = [System.Drawing.Image]::FromFile($rutaLogo) }
    $rutaSello = Join-Path $PSScriptRoot "Sello-Abuelo-Proof.png"
    if (Test-Path $rutaSello) { $script:SelloImg = [System.Drawing.Image]::FromFile($rutaSello) }
} catch { }

$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Location = New-Object System.Drawing.Point(0, 0)
$pnlHeader.Size = New-Object System.Drawing.Size($formWidth, 248)
$pnlHeader.BackColor = $script:ColFondo

$pnlHeader.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $w = $sender.Width

    # v7: el logo entero (mascota + nombre), igual que MEMMEM
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = "Center"

    if ($script:LogoImg) {
        $altoLogo = 44
        $anchoLogo = [int]($script:LogoImg.Width * $altoLogo / $script:LogoImg.Height)
        $g.DrawImage($script:LogoImg, [int](($w - $anchoLogo) / 2), 26, $anchoLogo, $altoLogo)
    }

    # la frase, que es lo que se lee primero
    $fFrase = New-Object System.Drawing.Font("Segoe UI Light", 26)
    $g.DrawString((Get-Text "v7Frase"), $fFrase, (New-Object System.Drawing.SolidBrush($script:ColNegro)), ($w / 2), 84, $sf)

    # dos lineas de apoyo
    $fSub = New-Object System.Drawing.Font("Segoe UI", 10)
    $g.DrawString((Get-Text "v7Sub1"), $fSub, (New-Object System.Drawing.SolidBrush($script:ColCyanDim)), ($w / 2), 132, $sf)
    $g.DrawString((Get-Text "v7Sub2"), $fSub, (New-Object System.Drawing.SolidBrush($script:ColCyanDim)), ($w / 2), 152, $sf)

    # v7: el mensaje que quita el miedo, con el sello ABUELO-PROOF
    $g.SmoothingMode = "AntiAlias"

    $fTranqui  = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $fTranqui2 = New-Object System.Drawing.Font("Segoe UI", 9)
    $fSello    = New-Object System.Drawing.Font("Segoe UI Semibold", 8)

    $txtSello   = Get-Text "v7Sello"
    $medSello   = $g.MeasureString($txtSello, $fSello)
    $anchoSello = [int]$medSello.Width + 22
    $altoSello  = 22

    $yCaja  = 176
    $altoCj = 62
    $margen = 34
    $rectCaja = New-Object System.Drawing.Rectangle($margen, $yCaja, ($w - $margen * 2), $altoCj)

    # fondo muy suave + borde fino, nada de cajas duras
    $brFondo = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(250, 250, 250))
    $g.FillRectangle($brFondo, $rectCaja)
    $penCaja = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(228, 228, 228), 1)
    $g.DrawRectangle($penCaja, $rectCaja)

    # el recuadrito negro con el texto, pisando el borde superior de la caja
    $fSelloTxt = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
    $txtSelloB = Get-Text "v7Sello"
    $medSelloB = $g.MeasureString($txtSelloB, $fSelloTxt)
    $anchoSelloB = [int]$medSelloB.Width + 22
    $xSelloB = $rectCaja.Left + 14
    $ySelloB = $yCaja - 11
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($script:ColNegro)), $xSelloB, $ySelloB, $anchoSelloB, 22)
    $sfCB = New-Object System.Drawing.StringFormat
    $sfCB.Alignment = "Center"; $sfCB.LineAlignment = "Center"
    $g.DrawString($txtSelloB, $fSelloTxt, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)), `
        (New-Object System.Drawing.RectangleF($xSelloB, $ySelloB, $anchoSelloB, 22)), $sfCB)

    # el sello ABUELO-PROOF de verdad, pisando la esquina derecha de la caja
    if ($script:SelloImg) {
        $ladoSello = 84
        $xSello = $rectCaja.Right - $ladoSello + 18
        $ySello = $yCaja + [int](($altoCj - $ladoSello) / 2)
        $g.DrawImage($script:SelloImg, $xSello, $ySello, $ladoSello, [int]($script:SelloImg.Height * $ladoSello / $script:SelloImg.Width))
    } else {
        $fSello = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
        $txtSello = Get-Text "v7Sello"
        $medSello = $g.MeasureString($txtSello, $fSello)
        $anchoSello = [int]$medSello.Width + 22
        $xSello = $rectCaja.Right - $anchoSello - 14
        $ySello = $yCaja - 11
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($script:ColNegro)), $xSello, $ySello, $anchoSello, 22)
        $sfC = New-Object System.Drawing.StringFormat
        $sfC.Alignment = "Center"; $sfC.LineAlignment = "Center"
        $g.DrawString($txtSello, $fSello, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)), `
            (New-Object System.Drawing.RectangleF($xSello, $ySello, $anchoSello, 22)), $sfC)
    }

    # las dos lineas, alineadas a la izquierda de la caja
    $sfL = New-Object System.Drawing.StringFormat
    $sfL.Alignment = "Near"
    $g.DrawString((Get-Text "v7Tranqui"), $fTranqui, (New-Object System.Drawing.SolidBrush($script:ColNegro)), `
        ($margen + 16), ($yCaja + 13), $sfL)
    $g.DrawString((Get-Text "v7Tranqui2"), $fTranqui2, (New-Object System.Drawing.SolidBrush($script:ColCyanDim)), `
        ($margen + 16), ($yCaja + 34), $sfL)
})

# --- Iconos integrados DENTRO del header panel ---
# Idioma (owner-drawn: bandera 50% opacidad + texto)
$btnLangH = New-Object System.Windows.Forms.Button
$btnLangH.FlatStyle = "Flat"
$btnLangH.FlatAppearance.BorderSize = 1
$btnLangH.FlatAppearance.BorderColor = $script:ColBorder
$btnLangH.FlatAppearance.MouseOverBackColor = $script:ColBoton
$btnLangH.BackColor = $script:ColBoton
$btnLangH.Text = ""
$btnLangH.Location = New-Object System.Drawing.Point(($formWidth - 70), 52)
$btnLangH.Size = New-Object System.Drawing.Size(40, 34)
$btnLangH.Cursor = "Hand"
$btnLangH.Tag = @{ Hover = $false }
$btnLangH.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $w = $sender.Width
    $h = $sender.Height
    $a = 128  # 50% opacidad
    # Bandera pequena centrada (no ocupa todo el boton)
    $fw = [int]($w * 0.55)
    $fh = [int]($fw * 0.65)
    $fx = [int](($w - $fw) / 2)
    $fy = 5
    if ($script:Lang -eq "es") {
        # Espana: rojo-amarillo-rojo
        $band = [int]($fh / 4)
        $rBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 170, 21, 27))
        $yBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 241, 191, 0))
        $g.FillRectangle($rBrush, $fx, $fy, $fw, $band)
        $g.FillRectangle($yBrush, $fx, ($fy + $band), $fw, ($fh - 2 * $band))
        $g.FillRectangle($rBrush, $fx, ($fy + $fh - $band), $fw, $band)
    } elseif ($script:Lang -eq "gl") {
        # Galicia: blanco con banda diagonal azul
        $wBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 255, 255, 255))
        $bBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 0, 119, 187))
        $g.FillRectangle($wBrush, $fx, $fy, $fw, $fh)
        $bPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($a, 0, 119, 187), [math]::Max(2, [int]($fh * 0.25)))
        $g.DrawLine($bPen, $fx, ($fy + $fh), ($fx + $fw), $fy)
    } else {
        # Inglaterra: Cruz de San Jorge (blanco + cruz roja)
        $wBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 255, 255, 255))
        $crBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 206, 17, 36))
        $g.FillRectangle($wBrush, $fx, $fy, $fw, $fh)
        $cr = [math]::Max(2, [int]($fw * 0.14))
        $g.FillRectangle($crBrush, [int]($fx + ($fw - $cr) / 2), $fy, $cr, $fh)
        $g.FillRectangle($crBrush, $fx, [int]($fy + ($fh - $cr) / 2), $fw, $cr)
    }
    # Texto idioma debajo de la bandera
    $fLang = New-Object System.Drawing.Font("Segoe UI", 6.5, [System.Drawing.FontStyle]::Bold)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = "Center"
    $sf.LineAlignment = "Near"
    $rect = New-Object System.Drawing.RectangleF(0, ($fy + $fh + 1), $w, ($h - $fy - $fh))
    $color = if ($sender.Tag.Hover) { $script:ColCyanBright } else { $script:ColCyanDark }
    $g.DrawString($script:Lang.ToUpper(), $fLang, (New-Object System.Drawing.SolidBrush($color)), $rect, $sf)
})
$btnLangH.Add_MouseEnter({
    $this.FlatAppearance.BorderColor = $script:ColBorderHover
    $this.Tag.Hover = $true
    $this.Invalidate()
    Play-HoverSound
})
$btnLangH.Add_MouseLeave({
    $this.FlatAppearance.BorderColor = $script:ColBorder
    $this.Tag.Hover = $false
    $this.Invalidate()
})
# v7: fuera del header (idioma en el pie, sonidos desactivados)
# $pnlHeader.Controls.Add($btnLangH)

# Sonido
$btnSoundH = New-Object System.Windows.Forms.Button
$btnSoundH.FlatStyle = "Flat"
$btnSoundH.FlatAppearance.BorderSize = 1
$btnSoundH.FlatAppearance.BorderColor = $script:ColBorder
$btnSoundH.FlatAppearance.MouseOverBackColor = $script:ColPanelHover
$btnSoundH.BackColor = $script:ColBoton
$btnSoundH.Location = New-Object System.Drawing.Point(($formWidth - 70), 14)
$btnSoundH.Size = New-Object System.Drawing.Size(40, 28)
$btnSoundH.Cursor = "Hand"
$btnSoundH.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode = "AntiAlias"
    $color = if ($script:SoundEnabled) { $script:ColCyanDark } else { $script:ColGris }
    $brush = New-Object System.Drawing.SolidBrush($color)
    $pen = New-Object System.Drawing.Pen($color, 1.5)
    # Altavoz compacto centrado (40x28 button)
    $g.FillPolygon($brush, @(
        (New-Object System.Drawing.Point(11, 10)),
        (New-Object System.Drawing.Point(15, 10)),
        (New-Object System.Drawing.Point(19, 6)),
        (New-Object System.Drawing.Point(19, 22)),
        (New-Object System.Drawing.Point(15, 18)),
        (New-Object System.Drawing.Point(11, 18))
    ))
    if ($script:SoundEnabled) {
        $g.DrawArc($pen, 21, 8, 6, 12, -60, 120)
    } else {
        $penX = New-Object System.Drawing.Pen($script:ColRojo, 1.5)
        $g.DrawLine($penX, 22, 8, 28, 20)
        $g.DrawLine($penX, 22, 20, 28, 8)
    }
})
$btnSoundH.Add_MouseEnter({
    $this.FlatAppearance.BorderColor = $script:ColBorderHover
    $this.Invalidate()
})
$btnSoundH.Add_MouseLeave({
    $this.FlatAppearance.BorderColor = $script:ColBorder
    $this.Invalidate()
})
$btnSoundH.Add_Click({
    $script:SoundEnabled = -not $script:SoundEnabled
    $this.Invalidate()
})
# v7: fuera del header (idioma en el pie, sonidos desactivados)
# $pnlHeader.Controls.Add($btnSoundH)

$form.Controls.Add($pnlHeader)

# ============================================================================
# FUNCION CREAR BOTON CON GLOW
# ============================================================================
function New-GlowButton {
    param(
        [string]$Titulo,
        [string]$Descripcion,
        [string]$Atajo,
        [int]$Y,
        [scriptblock]$OnClick
    )

    $btn = New-Object System.Windows.Forms.Button
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = $script:ColBorder
    $btn.FlatAppearance.MouseOverBackColor = $script:ColPanelHover
    $btn.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(20, 28, 45)
    $btn.BackColor = $script:ColBoton
    $btn.Location = New-Object System.Drawing.Point(50, $Y)
    $btn.Size = New-Object System.Drawing.Size(430, 90)
    $btn.Cursor = "Hand"
    $btn.Tag = @{Titulo = $Titulo; Desc = $Descripcion; Atajo = $Atajo; Hover = $false}

    $btn.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

        $fTitulo = New-Object System.Drawing.Font($script:citaroFamily, 16)
        $fDesc = New-Object System.Drawing.Font("Segoe UI", 10)
        $fAtajo = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

        $w = $sender.Width
        $h = $sender.Height

        if ($sender.Tag.Hover) {
            # Left edge bar (3px vertical cyan)
            $edgeBrush = New-Object System.Drawing.SolidBrush($script:ColCyan)
            $g.FillRectangle($edgeBrush, 0, 0, 3, $h)

            # Subtle glow gradient behind title area
            $glowRect = New-Object System.Drawing.Rectangle(3, 0, 120, $h)
            $glowBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                $glowRect,
                [System.Drawing.Color]::FromArgb(15, 0, 232, 255),
                [System.Drawing.Color]::FromArgb(0, 0, 232, 255),
                [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
            )
            $g.FillRectangle($glowBrush, $glowRect)

            # Full accent line (bottom)
            $accentPen = New-Object System.Drawing.Pen($script:ColCyan, 2)
            $g.DrawLine($accentPen, 12, ($h - 2), ($w - 12), ($h - 2))

            # Text
            $g.DrawString($sender.Tag.Titulo, $fTitulo, (New-Object System.Drawing.SolidBrush($script:ColCyanBright)), 18, 16)
            $g.DrawString($sender.Tag.Desc, $fDesc, (New-Object System.Drawing.SolidBrush($script:ColCyan)), 18, 50)
            $g.DrawString($sender.Tag.Atajo, $fAtajo, (New-Object System.Drawing.SolidBrush($script:ColCyanDark)), 380, 62)
        } else {
            # Subtle glow gradient behind title
            $glowRect = New-Object System.Drawing.Rectangle(0, 8, 80, 36)
            $glowBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                $glowRect,
                [System.Drawing.Color]::FromArgb(10, 0, 200, 255),
                [System.Drawing.Color]::FromArgb(0, 0, 200, 255),
                [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
            )
            $g.FillRectangle($glowBrush, $glowRect)

            # Partial accent line (60% width, bottom)
            $accentPen = New-Object System.Drawing.Pen($script:ColCyanDim, 1)
            $lineWidth = [int]($w * 0.6)
            $g.DrawLine($accentPen, 12, ($h - 2), (12 + $lineWidth), ($h - 2))

            # Text
            $g.DrawString($sender.Tag.Titulo, $fTitulo, (New-Object System.Drawing.SolidBrush($script:ColCyan)), 18, 16)
            $g.DrawString($sender.Tag.Desc, $fDesc, (New-Object System.Drawing.SolidBrush($script:ColCyanDark)), 18, 50)
            $g.DrawString($sender.Tag.Atajo, $fAtajo, (New-Object System.Drawing.SolidBrush($script:ColGris)), 380, 62)
        }
    })

    $btn.Add_MouseEnter({
        $this.FlatAppearance.BorderColor = $script:ColBorderHover
        $this.FlatAppearance.BorderSize = 2
        $this.Tag.Hover = $true
        $this.Invalidate()
        Play-HoverSound
    })
    $btn.Add_MouseLeave({
        $this.FlatAppearance.BorderColor = $script:ColBorder
        $this.FlatAppearance.BorderSize = 1
        $this.Tag.Hover = $false
        $this.Invalidate()
    })
    $btn.Add_Click($OnClick)

    return $btn
}

# ============================================================================
# FUNCION AUXILIAR - Lanzar Motor y Monitor lado a lado
# ============================================================================
function Start-FregonatorDual {
    param([string]$Modo)

    $form.Hide()
    if (Test-Path $script:ProgressFile) { Remove-Item $script:ProgressFile -Force -ErrorAction SilentlyContinue }

    # Lanzar Motor (admin, visible) - el usuario ve las barras animadas
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$script:FregonatorScript`" $Modo" -Verb RunAs
    Start-Sleep -Milliseconds 800

    # Lanzar Monitor GUI (ya se posiciona a la derecha automaticamente)
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$script:MonitorScript`""

    $form.Close()
}

# ============================================================================
# BOTON 1 - LIMPIEZA RAPIDA
# ============================================================================
# Separador top (bajo header)
$sepTop = New-Object System.Windows.Forms.Panel
$sepTop.Location = New-Object System.Drawing.Point(50, 120)
$sepTop.Size = New-Object System.Drawing.Size(430, 1)
$sepTop.BackColor = $script:ColGridLine
$form.Controls.Add($sepTop)

# ============================================================================
# v7: dos botones, como MEMMEM. El principal en negro solido, el otro solo
# con borde. Debajo, enlaces subrayados para lo secundario.
# ============================================================================
function New-BotonV7 {
    param(
        [string]$Clave,
        [int]$X,
        [int]$Y,
        [int]$Ancho = 210,
        [switch]$Principal,
        [scriptblock]$OnClick
    )

    $b = New-Object System.Windows.Forms.Button
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 1
    $b.Location = New-Object System.Drawing.Point($X, $Y)
    $b.Size = New-Object System.Drawing.Size($Ancho, 46)
    $b.Cursor = "Hand"
    $b.Text = ""
    $b.Tag = @{ Hover = $false; K = $Clave; P = [bool]$Principal }

    if ($Principal) {
        $b.BackColor = $script:ColNegro
        $b.FlatAppearance.BorderColor = $script:ColNegro
        $b.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
    } else {
        $b.BackColor = $script:ColFondo
        $b.FlatAppearance.BorderColor = $script:ColBorder
        $b.FlatAppearance.MouseOverBackColor = $script:ColPanelHover
    }

    $b.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = "Center"
        $sf.LineAlignment = "Center"
        $f = New-Object System.Drawing.Font("Segoe UI Semibold", 10.5)
        $col = if ($sender.Tag.P) { [System.Drawing.Color]::White } else { $script:ColNegro }
        $r = New-Object System.Drawing.RectangleF(0, 0, $sender.Width, $sender.Height)
        $g.DrawString((Get-Text $sender.Tag.K), $f, (New-Object System.Drawing.SolidBrush($col)), $r, $sf)
    })

    $b.Add_MouseEnter({ $this.Tag.Hover = $true;  $this.Invalidate() })
    $b.Add_MouseLeave({ $this.Tag.Hover = $false; $this.Invalidate() })
    $b.Add_Click($OnClick)
    return $b
}

# Los dos botones, centrados y juntos
$anchoBtn = 172
$hueco = 12
$xIzq = [int](($formWidth - ($anchoBtn * 3 + $hueco * 2)) / 2)

$btnBasica = New-BotonV7 -Clave "v7Basica" -X $xIzq -Y 281 -Ancho $anchoBtn -Principal -OnClick {
    Start-FregonatorDual -Modo "-AutoRapida"
}
$form.Controls.Add($btnBasica)

$btnAvanzada = New-BotonV7 -Clave "v7Avanzada" -X ($xIzq + $anchoBtn + $hueco) -Y 281 -Ancho $anchoBtn -OnClick {
    Start-FregonatorDual -Modo "-AutoAvanzada"
}
$form.Controls.Add($btnAvanzada)

$btnUltra = New-BotonV7 -Clave "v7Ultra" -X ($xIzq + ($anchoBtn + $hueco) * 2) -Y 281 -Ancho $anchoBtn -OnClick {
    Start-FregonatorDual -Modo "-AutoUltra"
}
$form.Controls.Add($btnUltra)

# Linea de apoyo bajo los botones
$lblNota = New-Object System.Windows.Forms.Label
$lblNota.Text = Get-Text "v7Nota"
$lblNota.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblNota.ForeColor = $script:ColCyanDim
$lblNota.BackColor = $script:ColFondo
$lblNota.TextAlign = "MiddleCenter"
$lblNota.Location = New-Object System.Drawing.Point(0, 348)
$lblNota.Size = New-Object System.Drawing.Size($formWidth, 22)
$form.Controls.Add($lblNota)

# ---------------------------------------------------------------------------
# Enlaces secundarios, sin cajas
# ---------------------------------------------------------------------------
function New-EnlaceV7 {
    param([string]$Clave, [int]$X, [int]$Y, [int]$Ancho, [scriptblock]$OnClick)
    $l = New-Object System.Windows.Forms.LinkLabel
    $l.Text = Get-Text $Clave
    $l.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $l.LinkColor = $script:ColCyanDark
    $l.ActiveLinkColor = $script:ColNegro
    $l.VisitedLinkColor = $script:ColCyanDark
    $l.BackColor = $script:ColFondo
    $l.TextAlign = "MiddleCenter"
    $l.Location = New-Object System.Drawing.Point($X, $Y)
    $l.Size = New-Object System.Drawing.Size($Ancho, 24)
    $l.Cursor = "Hand"
    $l.Add_LinkClicked($OnClick)
    return $l
}

$lnkTerminal = New-EnlaceV7 -Clave "v7Terminal" -X 0 -Y 384 -Ancho $formWidth -OnClick {
    $form.Hide()
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$script:FregonatorScript`"" -Verb RunAs
    $form.Close()
}
$form.Controls.Add($lnkTerminal)

# ============================================================================
# BOTON 4 - PROGRAMAR LIMPIEZA (OCULTO - Implementado pero no necesario por ahora)
# Codigo disponible en Show-SchedulerDialog, activar cuando se necesite
# ============================================================================
# $btn4 = New-GlowButton -Titulo "PROGRAMAR" -Descripcion "Limpieza automatica diaria/semanal" -Atajo "[4]" -Y 415 -OnClick {
#     Show-SchedulerDialog
# }
# $form.Controls.Add($btn4)

# ============================================================================
# DIALOGO PROGRAMADOR
# ============================================================================
function Show-SchedulerDialog {
    $taskName = "FREGONATOR_AutoClean"

    # Verificar estado actual
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    $statusText = if ($existingTask) {
        $nextRun = (Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue).NextRunTime
        if ($nextRun) { "$(Get-Text 'activo') - $(Get-Text 'proxima'): $($nextRun.ToString('dd/MM HH:mm'))" } else { Get-Text "activo" }
    } else { Get-Text "noConfigurado" }

    # Crear dialogo
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "FREGONATOR - Programador"
    $dlg.Size = New-Object System.Drawing.Size(400, 380)
    $dlg.BackColor = $script:ColFondo
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.StartPosition = "CenterParent"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false

    # Titulo
    $lblTitulo = New-Object System.Windows.Forms.Label
    $lblTitulo.Text = Get-Text "programarLimpieza"
    $lblTitulo.Font = New-Object System.Drawing.Font($script:citaroFamily, 16)
    $lblTitulo.ForeColor = $script:ColCyan
    $lblTitulo.Location = New-Object System.Drawing.Point(30, 20)
    $lblTitulo.AutoSize = $true
    $dlg.Controls.Add($lblTitulo)

    # Estado actual
    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = "$(Get-Text 'estado'): $statusText"
    $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblStatus.ForeColor = if ($existingTask) { $script:ColVerde } else { [System.Drawing.Color]::Gray }
    $lblStatus.Location = New-Object System.Drawing.Point(30, 55)
    $lblStatus.AutoSize = $true
    $dlg.Controls.Add($lblStatus)

    # Frecuencia
    $lblFreq = New-Object System.Windows.Forms.Label
    $lblFreq.Text = Get-Text "frecuencia"
    $lblFreq.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblFreq.ForeColor = $script:ColCyanDark
    $lblFreq.Location = New-Object System.Drawing.Point(30, 95)
    $lblFreq.AutoSize = $true
    $dlg.Controls.Add($lblFreq)

    $cmbFreq = New-Object System.Windows.Forms.ComboBox
    $cmbFreq.Items.AddRange(@((Get-Text "diariaRecomendado"), (Get-Text "semanal"), (Get-Text "alIniciarSesion")))
    $cmbFreq.SelectedIndex = 0
    $cmbFreq.Location = New-Object System.Drawing.Point(130, 92)
    $cmbFreq.Size = New-Object System.Drawing.Size(220, 25)
    $cmbFreq.DropDownStyle = "DropDownList"
    $cmbFreq.BackColor = $script:ColBoton
    $cmbFreq.ForeColor = [System.Drawing.Color]::White
    $dlg.Controls.Add($cmbFreq)

    # Hora
    $lblHora = New-Object System.Windows.Forms.Label
    $lblHora.Text = Get-Text "hora"
    $lblHora.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblHora.ForeColor = $script:ColCyanDark
    $lblHora.Location = New-Object System.Drawing.Point(30, 135)
    $lblHora.AutoSize = $true
    $dlg.Controls.Add($lblHora)

    $cmbHora = New-Object System.Windows.Forms.ComboBox
    $cmbHora.Items.AddRange(@("03:00 ($(Get-Text 'recomendado'))", "04:00", "05:00", "06:00", "12:00", "22:00", "23:00"))
    $cmbHora.SelectedIndex = 0
    $cmbHora.Location = New-Object System.Drawing.Point(130, 132)
    $cmbHora.Size = New-Object System.Drawing.Size(220, 25)
    $cmbHora.DropDownStyle = "DropDownList"
    $cmbHora.BackColor = $script:ColBoton
    $cmbHora.ForeColor = [System.Drawing.Color]::White
    $dlg.Controls.Add($cmbHora)

    # Info
    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = Get-Text "infoLimpieza"
    $lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lblInfo.ForeColor = [System.Drawing.Color]::Gray
    $lblInfo.Location = New-Object System.Drawing.Point(30, 175)
    $lblInfo.Size = New-Object System.Drawing.Size(320, 40)
    $dlg.Controls.Add($lblInfo)

    # Boton ACTIVAR
    $btnActivar = New-Object System.Windows.Forms.Button
    $btnActivar.Text = Get-Text "activar"
    $btnActivar.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $btnActivar.Location = New-Object System.Drawing.Point(30, 230)
    $btnActivar.Size = New-Object System.Drawing.Size(320, 40)
    $btnActivar.FlatStyle = "Flat"
    $btnActivar.FlatAppearance.BorderColor = $script:ColVerde
    $btnActivar.BackColor = $script:ColBoton
    $btnActivar.ForeColor = $script:ColVerde
    $btnActivar.Cursor = "Hand"
    $btnActivar.Add_Click({
        $hora = $cmbHora.SelectedItem -replace " \(recomendado\)", ""
        $freq = switch ($cmbFreq.SelectedIndex) { 0 { "Daily" }; 1 { "Weekly" }; 2 { "AtLogon" } }

        try {
            # Eliminar tarea existente
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

            # Crear nueva tarea
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script:FregonatorScript`" -Silent"

            $trigger = switch ($freq) {
                "Daily" { New-ScheduledTaskTrigger -Daily -At $hora }
                "Weekly" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At $hora }
                "AtLogon" { New-ScheduledTaskTrigger -AtLogon }
            }

            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction Stop | Out-Null

            [System.Windows.Forms.MessageBox]::Show("$(Get-Text 'tareaProgramadaCreada')`n`n$(Get-Text 'frecuenciaLabel'): $($cmbFreq.SelectedItem)`n$(Get-Text 'horaLabel'): $hora", "FREGONATOR", "OK", "Information")
            $dlg.Close()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("$(Get-Text 'errorAdmin')`n`n$_", "Error", "OK", "Error")
        }
    })
    $dlg.Controls.Add($btnActivar)

    # Boton DESACTIVAR
    $btnDesactivar = New-Object System.Windows.Forms.Button
    $btnDesactivar.Text = Get-Text "desactivar"
    $btnDesactivar.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $btnDesactivar.Location = New-Object System.Drawing.Point(30, 280)
    $btnDesactivar.Size = New-Object System.Drawing.Size(155, 35)
    $btnDesactivar.FlatStyle = "Flat"
    $btnDesactivar.FlatAppearance.BorderColor = $script:ColRojo
    $btnDesactivar.BackColor = $script:ColBoton
    $btnDesactivar.ForeColor = $script:ColRojo
    $btnDesactivar.Cursor = "Hand"
    $btnDesactivar.Enabled = ($existingTask -ne $null)
    $btnDesactivar.Add_Click({
        try {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show((Get-Text "tareaProgramadaEliminada"), "FREGONATOR", "OK", "Information")
            $dlg.Close()
        } catch {
            [System.Windows.Forms.MessageBox]::Show((Get-Text "noTareaProgramada"), "FREGONATOR", "OK", "Warning")
        }
    })
    $dlg.Controls.Add($btnDesactivar)

    # Boton CERRAR
    $btnCerrar = New-Object System.Windows.Forms.Button
    $btnCerrar.Text = Get-Text "cerrar"
    $btnCerrar.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $btnCerrar.Location = New-Object System.Drawing.Point(195, 280)
    $btnCerrar.Size = New-Object System.Drawing.Size(155, 35)
    $btnCerrar.FlatStyle = "Flat"
    $btnCerrar.FlatAppearance.BorderColor = $script:ColGris
    $btnCerrar.BackColor = $script:ColBoton
    $btnCerrar.ForeColor = $script:ColGris
    $btnCerrar.Cursor = "Hand"
    $btnCerrar.Add_Click({ $dlg.Close() })
    $dlg.Controls.Add($btnCerrar)

    [void]$dlg.ShowDialog($form)
}

# ============================================================================
# BOTON SALIR (secundario, sin glow)
# ============================================================================
$btnSalir = New-Object System.Windows.Forms.Button
$btnSalir.FlatStyle = "Flat"
$btnSalir.FlatAppearance.BorderSize = 1
$btnSalir.FlatAppearance.BorderColor = $script:ColGris
$btnSalir.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(30, 12, 14)
$btnSalir.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(40, 14, 16)
$btnSalir.BackColor = $script:ColBoton
$btnSalir.Location = New-Object System.Drawing.Point(50, 440)
$btnSalir.Size = New-Object System.Drawing.Size(430, 48)
$btnSalir.Cursor = "Hand"
$btnSalir.Tag = @{Hover = $false}

$btnSalir.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $fSalir = New-Object System.Drawing.Font($script:citaroFamily, 13)
    $color = if ($sender.Tag.Hover) { $script:ColRojo } else { $script:ColGris }
    # Center text with StringFormat
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = "Center"
    $sf.LineAlignment = "Center"
    $rect = New-Object System.Drawing.RectangleF(0, 0, $sender.Width, $sender.Height)
    $g.DrawString("[X] $(Get-Text 'salir')", $fSalir, (New-Object System.Drawing.SolidBrush($color)), $rect, $sf)
})

$btnSalir.Add_MouseEnter({
    $this.FlatAppearance.BorderColor = $script:ColRojo
    $this.Tag.Hover = $true
    $this.Invalidate()
    Play-HoverSound
})
$btnSalir.Add_MouseLeave({
    $this.FlatAppearance.BorderColor = $script:ColGris
    $this.Tag.Hover = $false
    $this.Invalidate()
})
$btnSalir.Add_Click({ $form.Close() })
# v7: el Salir grande fuera; en MEMMEM es un enlace del pie
# $form.Controls.Add($btnSalir)

# ============================================================================
# EVENTO CLICK IDIOMA (referencia a $btnLangH dentro del header)
# ============================================================================
$btnLangH.Add_Click({
    # Toggle idioma (es -> gl -> en -> es)
    $script:Lang = switch ($script:Lang) { "es" { "gl" }; "gl" { "en" }; default { "es" } }
    $this.Invalidate()  # Redibujar bandera + texto

    # Guardar preferencia
    $configFile = "$env:LOCALAPPDATA\FREGONATOR\lang.txt"
    $configDir = Split-Path $configFile
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    $script:Lang | Out-File $configFile -Force

    # Actualizar textos de botones en vivo
    $btn1.Tag.Titulo = Get-Text "limpiezaRapida"
    $btn1.Tag.Desc = Get-Text "descRapida"
    $btn1.Invalidate()

    $btn2.Tag.Titulo = Get-Text "limpiezaCompleta"
    $btn2.Tag.Desc = Get-Text "descCompleta"
    $btn2.Invalidate()

    $btn3.Tag.Titulo = Get-Text "terminal"
    $btn3.Tag.Desc = Get-Text "descTerminal"
    $btn3.Invalidate()

    $btnSalir.Text = "[X] " + (Get-Text "salir")
})

# ============================================================================
# FOOTER
# ============================================================================
# Separador bottom
$sepBottom = New-Object System.Windows.Forms.Panel
$sepBottom.Location = New-Object System.Drawing.Point(50, 504)
$sepBottom.Size = New-Object System.Drawing.Size(430, 1)
$sepBottom.BackColor = $script:ColGridLine
$form.Controls.Add($sepBottom)

$footerDim = [System.Drawing.Color]::FromArgb(45, 50, 60)

# Footer centrado: usar un panel owner-drawn para centrar perfectamente
# ============================================================================
# PIE v7: Salir | idioma | version con fecha. Igual que MEMMEM.
# ============================================================================
$yPie = $formHeight - 78

$lnkSalir = New-Object System.Windows.Forms.LinkLabel
$lnkSalir.Text = Get-Text "v7Salir"
$lnkSalir.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lnkSalir.LinkColor = $script:ColCyanDim
$lnkSalir.ActiveLinkColor = $script:ColNegro
$lnkSalir.BackColor = $script:ColFondo
$lnkSalir.TextAlign = "MiddleRight"
$lnkSalir.Location = New-Object System.Drawing.Point(150, $yPie)
$lnkSalir.Size = New-Object System.Drawing.Size(60, 26)
$lnkSalir.Cursor = "Hand"
$lnkSalir.Add_LinkClicked({ $form.Close() })
$form.Controls.Add($lnkSalir)

$cmbIdioma = New-Object System.Windows.Forms.ComboBox
$cmbIdioma.DropDownStyle = "DropDownList"
$cmbIdioma.FlatStyle = "Flat"
$cmbIdioma.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$cmbIdioma.BackColor = $script:ColFondo
$cmbIdioma.ForeColor = $script:ColNegro
$cmbIdioma.Location = New-Object System.Drawing.Point(215, $yPie)
$cmbIdioma.Size = New-Object System.Drawing.Size(110, 26)
[void]$cmbIdioma.Items.AddRange(@("Español", "Galego", "English"))
$cmbIdioma.SelectedIndex = switch ($script:Lang) { "es" { 0 }; "gl" { 1 }; default { 2 } }
$cmbIdioma.Add_SelectedIndexChanged({
    $script:Lang = switch ($cmbIdioma.SelectedIndex) { 0 { "es" }; 1 { "gl" }; default { "en" } }
    $form.Refresh()
    foreach ($c in $form.Controls) {
        if ($c.Tag -and $c.Tag.K) { $c.Invalidate() }
        elseif ($c -is [System.Windows.Forms.LinkLabel] -or $c -is [System.Windows.Forms.Label]) { $c.Invalidate() }
    }
    $lnkSalir.Text    = Get-Text "v7Salir"
    $lnkTerminal.Text = Get-Text "v7Terminal"
    $lblNota.Text     = Get-Text "v7Nota"
    $lblVersionV7.Text = "FREGONATOR " + (Get-Text "version")
})
$form.Controls.Add($cmbIdioma)

$lblVersionV7 = New-Object System.Windows.Forms.Label
$lblVersionV7.Text = "FREGONATOR " + (Get-Text "version")
$lblVersionV7.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblVersionV7.ForeColor = $script:ColCyanDim
$lblVersionV7.BackColor = $script:ColFondo
$lblVersionV7.TextAlign = "MiddleLeft"
$lblVersionV7.Location = New-Object System.Drawing.Point(338, $yPie)
$lblVersionV7.Size = New-Object System.Drawing.Size(220, 26)
$form.Controls.Add($lblVersionV7)

# ============================================================================
# ATAJOS DE TECLADO
# ============================================================================
$form.Add_KeyDown({
    param($sender, $e)
    switch ($e.KeyCode) {
        "D1" { $btn1.PerformClick() }
        "NumPad1" { $btn1.PerformClick() }
        "D2" { $btn2.PerformClick() }
        "NumPad2" { $btn2.PerformClick() }
        "D3" { $btn3.PerformClick() }
        "NumPad3" { $btn3.PerformClick() }
        # "D4" { $btn4.PerformClick() }  # OCULTO
        # "NumPad4" { $btn4.PerformClick() }  # OCULTO
        "X" { $btnSalir.PerformClick() }
        "Escape" { $btnSalir.PerformClick() }
    }
})
$form.KeyPreview = $true

# ============================================================================
# EVENTO AL MOSTRAR - Ladrido de Nala
# ============================================================================
$form.Add_Shown({
    # v7: sin sonidos (decision CEO 31/07/2026)
    $form.Refresh()
})


# ============================================================================
# DESPEDIDA v7 - Tequila y Nala. Sin nombres, sin texto encima.
# ============================================================================
function Show-DespedidaV7 {
    $rutaFoto = Join-Path $script:ScriptPath "nala-tequila.jpg"
    if (-not (Test-Path $rutaFoto)) { return }

    try { $foto = [System.Drawing.Image]::FromFile($rutaFoto) } catch { return }

    $d = New-Object System.Windows.Forms.Form
    $d.FormBorderStyle = "None"
    $d.StartPosition = "CenterScreen"
    $d.BackColor = [System.Drawing.Color]::White
    $d.TopMost = $true
    $d.ShowInTaskbar = $false

    $margen = 26
    $d.Size = New-Object System.Drawing.Size(($foto.Width + $margen * 2), ($foto.Height + $margen * 2 + 34))

    $pb = New-Object System.Windows.Forms.PictureBox
    $pb.Image = $foto
    $pb.SizeMode = "Zoom"
    $pb.Location = New-Object System.Drawing.Point($margen, $margen)
    $pb.Size = New-Object System.Drawing.Size($foto.Width, $foto.Height)
    $d.Controls.Add($pb)

    # borde fino, como el resto de la app
    $d.Add_Paint({
        param($sender, $e)
        $lapiz = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(225, 225, 225), 1)
        $e.Graphics.DrawRectangle($lapiz, 0, 0, ($sender.Width - 1), ($sender.Height - 1))
    })

    # se cierra sola, o con un clic, o con una tecla
    $t = New-Object System.Windows.Forms.Timer
    $t.Interval = 2600
    $t.Add_Tick({ $t.Stop(); $d.Close() })
    $t.Start()

    $d.Add_Click({ $d.Close() })
    $pb.Add_Click({ $d.Close() })
    $d.KeyPreview = $true
    $d.Add_KeyDown({ $d.Close() })

    [void]$d.ShowDialog()
    $d.Dispose()
}

# ============================================================================
# MOSTRAR (Show + Application.Run para soportar systray hide/show)
# ============================================================================
[System.Windows.Forms.Application]::Run($form)

# v7: Tequila y Nala al cerrar
Show-DespedidaV7

# Liberar mutex y tray al cerrar
$script:TrayIcon.Visible = $false
$script:TrayIcon.Dispose()
try { $script:FregMutex.ReleaseMutex() } catch {}
$script:FregMutex.Dispose()
