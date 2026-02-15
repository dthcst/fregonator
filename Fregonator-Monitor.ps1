<#
    FREGONATOR MONITOR v6.0
    Panel de progreso en tiempo real
    - Oculto de barra de tareas (solo visible en pantalla)
    - Muestra actividad real (archivos/apps procesandose)
    2026
#>

param(
    [string]$LogFile = "$env:PUBLIC\fregonator_progress.json"
)

# =============================================================================
# OCULTAR CONSOLA DE POWERSHELL (solo mostrar GUI)
# =============================================================================
try {
    Add-Type -Name Window -Namespace Console -MemberDefinition '
        [DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0) | Out-Null  # 0 = SW_HIDE
} catch {
    # Fallback si Win32 falla (0xc0000142) - consola visible pero GUI funciona
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogoPath = Join-Path $ScriptPath "Logo-Fregonator-001.png"
$FontPath = Join-Path $ScriptPath "_FUENTES\citaro_voor_dubbele_hoogte_breed\citaro_voor_dubbele_hoogte_breed.ttf"
$AbortFile = "$env:PUBLIC\fregonator_abort.flag"
$LauncherScript = Join-Path $ScriptPath "Fregonator-Launcher.ps1"
$SoundPath = Join-Path $ScriptPath "sounds\bark.wav"

# =============================================================================
# IDIOMA - Leer preferencia guardada
# =============================================================================
function Get-SystemLanguage {
    $configFile = "$env:LOCALAPPDATA\FREGONATOR\lang.txt"
    if (Test-Path $configFile) {
        $saved = (Get-Content $configFile -Raw).Trim()
        if ($saved -eq "en" -or $saved -eq "es") { return $saved }
    }
    $uiCulture = (Get-UICulture).Name
    if ($uiCulture -like "en*") { return "en" }
    return "es"
}
$script:Lang = Get-SystemLanguage

$script:Texts = @{
    es = @{
        tareas = "TAREAS"
        liberado = "LIBERADO"
        velocidad = "VELOCIDAD"
        procesando = "PROCESANDO:"
        abortar = "ABORTAR"
        volver = "[V] VOLVER AL MENU"
        salir = "[X] SALIR"
        completado = "LIMPIEZA COMPLETADA!"
        tareasFinalizadas = "Todas las tareas finalizadas"
        liberadosEn = "liberados en"
        completadoMsg = "COMPLETADO:"
        iniciando = "> INICIANDO..."
        esperando = "Esperando inicio..."
        actividad = "ACTIVIDAD:"
        abortando = "ABORTANDO..."
        monitorIniciado = "Monitor iniciado - Esperando datos..."
    }
    en = @{
        tareas = "TASKS"
        liberado = "FREED"
        velocidad = "SPEED"
        procesando = "PROCESSING:"
        abortar = "ABORT"
        volver = "[V] BACK TO MENU"
        salir = "[X] EXIT"
        completado = "CLEANUP COMPLETED!"
        tareasFinalizadas = "All tasks completed"
        liberadosEn = "freed in"
        completadoMsg = "COMPLETED:"
        iniciando = "> STARTING..."
        esperando = "Waiting to start..."
        actividad = "ACTIVITY:"
        abortando = "ABORTING..."
        monitorIniciado = "Monitor started - Waiting for data..."
    }
}
function Get-Text($key) { $script:Texts[$script:Lang][$key] }

# Cargar fuente Citaro
$script:privateFonts = New-Object System.Drawing.Text.PrivateFontCollection
if (Test-Path $FontPath) {
    $script:privateFonts.AddFontFile($FontPath)
    $script:citaroFamily = $script:privateFonts.Families[0]
} else {
    $script:citaroFamily = [System.Drawing.FontFamily]::GenericMonospace
}

# =============================================================================
# PALETA DE COLORES - Tron Legacy (v6.0)
# =============================================================================
$script:ColFondo       = [System.Drawing.Color]::FromArgb(6, 8, 14)
$script:ColPanel       = [System.Drawing.Color]::FromArgb(12, 16, 26)
$script:ColCyan        = [System.Drawing.Color]::FromArgb(0, 232, 255)
$script:ColCyanBright  = [System.Drawing.Color]::FromArgb(102, 240, 255)
$script:ColCyanDark    = [System.Drawing.Color]::FromArgb(0, 160, 180)
$script:ColCyanDim     = [System.Drawing.Color]::FromArgb(0, 80, 100)
$script:ColGris        = [System.Drawing.Color]::FromArgb(55, 62, 75)
$script:ColGrisOsc     = [System.Drawing.Color]::FromArgb(18, 22, 32)
$script:ColVerde       = [System.Drawing.Color]::FromArgb(0, 230, 120)
$script:ColAmarillo    = [System.Drawing.Color]::FromArgb(255, 220, 0)
$script:ColRojo        = [System.Drawing.Color]::FromArgb(255, 70, 70)
$script:ColNaranja     = [System.Drawing.Color]::FromArgb(255, 150, 50)
$script:ColBorder      = [System.Drawing.Color]::FromArgb(0, 120, 140)
$script:ColBorderHover = [System.Drawing.Color]::FromArgb(0, 232, 255)
$script:ColPanelHover  = [System.Drawing.Color]::FromArgb(16, 22, 36)
$script:ColGridLine    = [System.Drawing.Color]::FromArgb(15, 20, 32)
$script:ColGold        = [System.Drawing.Color]::FromArgb(200, 170, 50)

# Estado global
$script:TiempoInicio = [DateTime]::Now
$script:UltimoLog = ""
$script:Terminado = $false
$script:UltimaTarea = ""
$script:TareasCompletadas = @()
$script:AnimFrame = 0

# =============================================================================
# HELPER - Rounded Rectangle Path para GDI+
# =============================================================================
function New-RoundedRectPath {
    param([System.Drawing.Rectangle]$Rect, [int]$Radius)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $Radius * 2
    $path.AddArc($Rect.X, $Rect.Y, $d, $d, 180, 90)
    $path.AddArc(($Rect.Right - $d), $Rect.Y, $d, $d, 270, 90)
    $path.AddArc(($Rect.Right - $d), ($Rect.Bottom - $d), $d, $d, 0, 90)
    $path.AddArc($Rect.X, ($Rect.Bottom - $d), $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

# =============================================================================
# VENTANA PRINCIPAL - Compacta, posicionada a la derecha del Terminal
# =============================================================================
$formWidth = 480
$formHeight = 680

$form = New-Object System.Windows.Forms.Form
$form.Text = "FREGONATOR MONITOR"
$form.Size = New-Object System.Drawing.Size($formWidth, $formHeight)
$form.FormBorderStyle = "None"
$form.BackColor = $script:ColFondo
$form.TopMost = $true
$form.ShowInTaskbar = $false  # No aparece en barra de tareas

# CENTRAR junto a la Terminal (1040x720)
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$terminalWidth = 1040
$terminalHeight = 720
$gap = 10
$totalWidth = $terminalWidth + $gap + $formWidth
$startX = [int]($screen.X + ($screen.Width - $totalWidth) / 2)
$monitorX = $startX + $terminalWidth + $gap
$form.StartPosition = "Manual"
$form.Location = New-Object System.Drawing.Point(
    $monitorX,
    [int]($screen.Y + ($screen.Height - $terminalHeight) / 2)
)

# =============================================================================
# BARRA DE TITULO CUSTOM (draggable)
# =============================================================================
$pnlTitulo = New-Object System.Windows.Forms.Panel
$pnlTitulo.Location = New-Object System.Drawing.Point(0, 0)
$pnlTitulo.Size = New-Object System.Drawing.Size($formWidth, 32)
$pnlTitulo.BackColor = $script:ColPanel

$pnlTitulo.Add_MouseDown({
    $script:dragging = $true
    $script:dragStart = [System.Windows.Forms.Cursor]::Position
    $script:formStart = $form.Location
})
$pnlTitulo.Add_MouseMove({
    if ($script:dragging) {
        $current = [System.Windows.Forms.Cursor]::Position
        $form.Location = New-Object System.Drawing.Point(
            ($script:formStart.X + $current.X - $script:dragStart.X),
            ($script:formStart.Y + $current.Y - $script:dragStart.Y)
        )
    }
})
$pnlTitulo.Add_MouseUp({ $script:dragging = $false })

# Bottom border on title bar
$pnlTitulo.Add_Paint({
    param($sender, $e)
    $e.Graphics.DrawLine(
        (New-Object System.Drawing.Pen($script:ColBorder, 1)),
        0, ($sender.Height - 1), $sender.Width, ($sender.Height - 1)
    )
})
$form.Controls.Add($pnlTitulo)

# Icono y titulo
$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text = "FREGONATOR MONITOR"
$lblTitulo.Font = New-Object System.Drawing.Font($script:citaroFamily, 9)
$lblTitulo.ForeColor = $script:ColCyanDark
$lblTitulo.Location = New-Object System.Drawing.Point(12, 8)
$lblTitulo.AutoSize = $true
$pnlTitulo.Controls.Add($lblTitulo)

# Boton minimizar
$btnMin = New-Object System.Windows.Forms.Button
$btnMin.Text = [char]0x2013  # en-dash como guion
$btnMin.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnMin.ForeColor = $script:ColGris
$btnMin.BackColor = $script:ColPanel
$btnMin.FlatStyle = "Flat"
$btnMin.FlatAppearance.BorderSize = 0
$btnMin.FlatAppearance.MouseOverBackColor = $script:ColCyanDark
$btnMin.Location = New-Object System.Drawing.Point(($formWidth - 75), 0)
$btnMin.Size = New-Object System.Drawing.Size(38, 32)
$btnMin.Add_Click({ $form.WindowState = "Minimized" })
$btnMin.Add_MouseEnter({ $this.ForeColor = [System.Drawing.Color]::White })
$btnMin.Add_MouseLeave({ $this.ForeColor = $script:ColGris })
$pnlTitulo.Controls.Add($btnMin)

# Boton cerrar
$btnX = New-Object System.Windows.Forms.Button
$btnX.Text = [char]0x2715  # X elegante
$btnX.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnX.ForeColor = $script:ColGris
$btnX.BackColor = $script:ColPanel
$btnX.FlatStyle = "Flat"
$btnX.FlatAppearance.BorderSize = 0
$btnX.FlatAppearance.MouseOverBackColor = $script:ColRojo
$btnX.Location = New-Object System.Drawing.Point(($formWidth - 38), 0)
$btnX.Size = New-Object System.Drawing.Size(38, 32)
$btnX.Add_Click({ $form.Close() })
$btnX.Add_MouseEnter({ $this.ForeColor = [System.Drawing.Color]::White })
$btnX.Add_MouseLeave({ $this.ForeColor = $script:ColGris })
$pnlTitulo.Controls.Add($btnX)

# =============================================================================
# LOGO
# =============================================================================
if (Test-Path $LogoPath) {
    $picLogo = New-Object System.Windows.Forms.PictureBox
    $picLogo.Image = [System.Drawing.Image]::FromFile($LogoPath)
    $picLogo.SizeMode = "Zoom"
    $picLogo.Location = New-Object System.Drawing.Point(20, 42)
    $picLogo.Size = New-Object System.Drawing.Size(200, 50)
    $picLogo.BackColor = $script:ColFondo
    $form.Controls.Add($picLogo)
}

# =============================================================================
# ETAPA ACTUAL + SPINNER
# =============================================================================
$lblEtapa = New-Object System.Windows.Forms.Label
$lblEtapa.Text = (Get-Text "iniciando")
$lblEtapa.Font = New-Object System.Drawing.Font($script:citaroFamily, 14)
$lblEtapa.ForeColor = $script:ColCyan
$lblEtapa.BackColor = $script:ColFondo
$lblEtapa.Location = New-Object System.Drawing.Point(20, 100)
$lblEtapa.Size = New-Object System.Drawing.Size(($formWidth - 40), 28)
$form.Controls.Add($lblEtapa)

# =============================================================================
# BARRA DE PROGRESO PRINCIPAL (Owner-drawn GDI+)
# =============================================================================
$pnlProgressBar = New-Object System.Windows.Forms.Panel
$pnlProgressBar.Location = New-Object System.Drawing.Point(20, 135)
$pnlProgressBar.Size = New-Object System.Drawing.Size(($formWidth - 40), 32)
$pnlProgressBar.BackColor = $script:ColFondo
$pnlProgressBar.Tag = @{Progress = 0; Completed = $false}

$pnlProgressBar.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $w = $sender.Width
    $h = $sender.Height
    $prog = $sender.Tag.Progress
    $done = $sender.Tag.Completed

    # Track background (rounded rect)
    $trackRect = New-Object System.Drawing.Rectangle(0, 0, ($w - 1), ($h - 1))
    $trackPath = New-RoundedRectPath -Rect $trackRect -Radius 4
    $trackBrush = New-Object System.Drawing.SolidBrush($script:ColGrisOsc)
    $g.FillPath($trackBrush, $trackPath)

    if ($prog -gt 0) {
        $fillWidth = [int](($prog / 100.0) * $w)
        if ($fillWidth -lt 8) { $fillWidth = 8 }
        $fillRect = New-Object System.Drawing.Rectangle(0, 0, $fillWidth, ($h - 1))
        $fillPath = New-RoundedRectPath -Rect $fillRect -Radius 4

        # Gradient fill
        $gradRect = New-Object System.Drawing.Rectangle(0, 0, ($fillWidth + 1), $h)
        if ($done) {
            $gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                $gradRect,
                [System.Drawing.Color]::FromArgb(0, 160, 80),
                $script:ColVerde,
                [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
            )
        } else {
            $gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                $gradRect,
                $script:ColCyanDark,
                $script:ColCyan,
                [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
            )
        }
        $g.FillPath($gradBrush, $fillPath)

        # Scanlines (retro texture)
        $scanPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 0, 0, 0), 1)
        for ($sy = 0; $sy -lt $h; $sy += 4) {
            $g.DrawLine($scanPen, 0, $sy, $fillWidth, $sy)
        }

        # Leading edge (bright vertical line)
        if (-not $done -and $fillWidth -gt 4) {
            $edgeColor = if ($done) { $script:ColVerde } else { $script:ColCyanBright }
            $edgePen = New-Object System.Drawing.Pen($edgeColor, 2)
            $g.DrawLine($edgePen, ($fillWidth - 1), 2, ($fillWidth - 1), ($h - 3))
        }
    }

    # Tick marks at 25/50/75%
    $tickPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 255, 255, 255), 1)
    foreach ($pct in @(25, 50, 75)) {
        $tx = [int]($w * $pct / 100.0)
        $g.DrawLine($tickPen, $tx, ($h - 5), $tx, ($h - 1))
    }
})
$form.Controls.Add($pnlProgressBar)

# =============================================================================
# PORCENTAJE GRANDE + TIEMPO
# =============================================================================
$lblPorcentaje = New-Object System.Windows.Forms.Label
$lblPorcentaje.Text = "0%"
$lblPorcentaje.Font = New-Object System.Drawing.Font("Consolas", 42, [System.Drawing.FontStyle]::Bold)
$lblPorcentaje.ForeColor = $script:ColCyan
$lblPorcentaje.BackColor = $script:ColFondo
$lblPorcentaje.Location = New-Object System.Drawing.Point(20, 175)
$lblPorcentaje.Size = New-Object System.Drawing.Size(200, 60)
$lblPorcentaje.TextAlign = "MiddleLeft"
$form.Controls.Add($lblPorcentaje)

$lblTiempo = New-Object System.Windows.Forms.Label
$lblTiempo.Text = "00:00"
$lblTiempo.Font = New-Object System.Drawing.Font($script:citaroFamily, 24)
$lblTiempo.ForeColor = $script:ColCyanDark
$lblTiempo.BackColor = $script:ColFondo
$lblTiempo.Location = New-Object System.Drawing.Point(320, 185)
$lblTiempo.Size = New-Object System.Drawing.Size(140, 40)
$lblTiempo.TextAlign = "MiddleRight"
$form.Controls.Add($lblTiempo)

# =============================================================================
# PANEL ESTADISTICAS - 3 Cards separadas
# =============================================================================
$cardWidth = [int]((($formWidth - 40) - 20) / 3)  # 3 cards con 10px gap x2
$cardY = 245
$cardH = 80

# Card 1: Tareas
$pnlCardTareas = New-Object System.Windows.Forms.Panel
$pnlCardTareas.Location = New-Object System.Drawing.Point(20, $cardY)
$pnlCardTareas.Size = New-Object System.Drawing.Size($cardWidth, $cardH)
$pnlCardTareas.BackColor = $script:ColPanel

$pnlCardTareas.Add_Paint({
    param($sender, $e)
    $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush($script:ColCyanDim)), 0, 0, $sender.Width, 2)
})

$lblTareasIcon = New-Object System.Windows.Forms.Label
$lblTareasIcon.Text = (Get-Text "tareas")
$lblTareasIcon.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblTareasIcon.ForeColor = $script:ColGris
$lblTareasIcon.Location = New-Object System.Drawing.Point(10, 10)
$lblTareasIcon.AutoSize = $true
$pnlCardTareas.Controls.Add($lblTareasIcon)

$lblTareas = New-Object System.Windows.Forms.Label
$lblTareas.Text = "0/8"
$lblTareas.Font = New-Object System.Drawing.Font($script:citaroFamily, 15)
$lblTareas.ForeColor = $script:ColCyan
$lblTareas.Location = New-Object System.Drawing.Point(8, 34)
$lblTareas.Size = New-Object System.Drawing.Size(($cardWidth - 10), 38)
$pnlCardTareas.Controls.Add($lblTareas)
$form.Controls.Add($pnlCardTareas)

# Card 2: Espacio
$card2X = 20 + $cardWidth + 10
$pnlCardEspacio = New-Object System.Windows.Forms.Panel
$pnlCardEspacio.Location = New-Object System.Drawing.Point($card2X, $cardY)
$pnlCardEspacio.Size = New-Object System.Drawing.Size($cardWidth, $cardH)
$pnlCardEspacio.BackColor = $script:ColPanel

$pnlCardEspacio.Add_Paint({
    param($sender, $e)
    $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 120, 60))), 0, 0, $sender.Width, 2)
})

$lblEspacioIcon = New-Object System.Windows.Forms.Label
$lblEspacioIcon.Text = (Get-Text "liberado")
$lblEspacioIcon.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblEspacioIcon.ForeColor = $script:ColGris
$lblEspacioIcon.Location = New-Object System.Drawing.Point(10, 10)
$lblEspacioIcon.AutoSize = $true
$pnlCardEspacio.Controls.Add($lblEspacioIcon)

$lblEspacio = New-Object System.Windows.Forms.Label
$lblEspacio.Text = "0 MB"
$lblEspacio.Font = New-Object System.Drawing.Font($script:citaroFamily, 15)
$lblEspacio.ForeColor = $script:ColVerde
$lblEspacio.Location = New-Object System.Drawing.Point(8, 34)
$lblEspacio.Size = New-Object System.Drawing.Size(($cardWidth - 10), 38)
$pnlCardEspacio.Controls.Add($lblEspacio)
$form.Controls.Add($pnlCardEspacio)

# Card 3: Velocidad
$card3X = 20 + ($cardWidth + 10) * 2
$pnlCardVelocidad = New-Object System.Windows.Forms.Panel
$pnlCardVelocidad.Location = New-Object System.Drawing.Point($card3X, $cardY)
$pnlCardVelocidad.Size = New-Object System.Drawing.Size($cardWidth, $cardH)
$pnlCardVelocidad.BackColor = $script:ColPanel

$pnlCardVelocidad.Add_Paint({
    param($sender, $e)
    $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush($script:ColGold)), 0, 0, $sender.Width, 2)
})

$lblVelocidadIcon = New-Object System.Windows.Forms.Label
$lblVelocidadIcon.Text = (Get-Text "velocidad")
$lblVelocidadIcon.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblVelocidadIcon.ForeColor = $script:ColGris
$lblVelocidadIcon.Location = New-Object System.Drawing.Point(10, 10)
$lblVelocidadIcon.AutoSize = $true
$pnlCardVelocidad.Controls.Add($lblVelocidadIcon)

$lblVelocidad = New-Object System.Windows.Forms.Label
$lblVelocidad.Text = "-- /s"
$lblVelocidad.Font = New-Object System.Drawing.Font($script:citaroFamily, 15)
$lblVelocidad.ForeColor = $script:ColAmarillo
$lblVelocidad.Location = New-Object System.Drawing.Point(8, 34)
$lblVelocidad.Size = New-Object System.Drawing.Size(($cardWidth - 10), 38)
$pnlCardVelocidad.Controls.Add($lblVelocidad)
$form.Controls.Add($pnlCardVelocidad)

# =============================================================================
# TAREA ACTUAL - Mas prominente
# =============================================================================
$lblTareaLabel = New-Object System.Windows.Forms.Label
$lblTareaLabel.Text = (Get-Text "procesando")
$lblTareaLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$lblTareaLabel.ForeColor = $script:ColCyanDim
$lblTareaLabel.Location = New-Object System.Drawing.Point(20, 338)
$lblTareaLabel.AutoSize = $true
$form.Controls.Add($lblTareaLabel)

$lblTareaActual = New-Object System.Windows.Forms.Label
$lblTareaActual.Text = (Get-Text "esperando")
$lblTareaActual.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$lblTareaActual.ForeColor = $script:ColCyan
$lblTareaActual.BackColor = $script:ColPanel
$lblTareaActual.Location = New-Object System.Drawing.Point(20, 358)
$lblTareaActual.Size = New-Object System.Drawing.Size(($formWidth - 40), 28)
$lblTareaActual.Padding = New-Object System.Windows.Forms.Padding(8, 5, 8, 5)
$form.Controls.Add($lblTareaActual)

# =============================================================================
# LOG DE ACTIVIDAD
# =============================================================================
$lblLogLabel = New-Object System.Windows.Forms.Label
$lblLogLabel.Text = (Get-Text "actividad")
$lblLogLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$lblLogLabel.ForeColor = $script:ColCyanDim
$lblLogLabel.Location = New-Object System.Drawing.Point(20, 396)
$lblLogLabel.AutoSize = $true
$form.Controls.Add($lblLogLabel)

# Top border for log area
$sepLog = New-Object System.Windows.Forms.Panel
$sepLog.Location = New-Object System.Drawing.Point(20, 414)
$sepLog.Size = New-Object System.Drawing.Size(($formWidth - 40), 1)
$sepLog.BackColor = $script:ColGridLine
$form.Controls.Add($sepLog)

# Try Cascadia Mono, fallback Consolas
$logFontFamily = "Consolas"
try {
    $testFont = New-Object System.Drawing.Font("Cascadia Mono", 9.5)
    if ($testFont.Name -eq "Cascadia Mono") { $logFontFamily = "Cascadia Mono" }
    $testFont.Dispose()
} catch {}

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font($logFontFamily, 9.5)
$txtLog.ForeColor = $script:ColCyanDark
$txtLog.BackColor = $script:ColGrisOsc
$txtLog.BorderStyle = "None"
$txtLog.Location = New-Object System.Drawing.Point(20, 416)
$txtLog.Size = New-Object System.Drawing.Size(($formWidth - 40), 107)
$form.Controls.Add($txtLog)

# =============================================================================
# BOTON ABORTAR (se oculta al terminar)
# =============================================================================
$btnAbortar = New-Object System.Windows.Forms.Button
$btnAbortar.Text = (Get-Text "abortar")
$btnAbortar.Font = New-Object System.Drawing.Font($script:citaroFamily, 14)
$btnAbortar.ForeColor = $script:ColRojo
$btnAbortar.BackColor = $script:ColPanel
$btnAbortar.FlatStyle = "Flat"
$btnAbortar.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(120, 40, 40)
$btnAbortar.FlatAppearance.BorderSize = 1
$btnAbortar.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(35, 14, 16)
$btnAbortar.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(50, 18, 20)
$btnAbortar.Location = New-Object System.Drawing.Point(20, 535)
$btnAbortar.Size = New-Object System.Drawing.Size(($formWidth - 40), 50)
$btnAbortar.Cursor = "Hand"
$btnAbortar.Add_MouseEnter({
    $this.FlatAppearance.BorderColor = $script:ColRojo
    $this.FlatAppearance.BorderSize = 2
    $this.ForeColor = [System.Drawing.Color]::FromArgb(255, 140, 140)
})
$btnAbortar.Add_MouseLeave({
    $this.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(120, 40, 40)
    $this.FlatAppearance.BorderSize = 1
    $this.ForeColor = $script:ColRojo
})
$btnAbortar.Add_Click({
    "ABORT" | Out-File $AbortFile -Force
    $ts = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$ts] $(Get-Text 'abortando')`r`n")
    $this.Enabled = $false
    $this.Text = (Get-Text "abortando")
    $this.ForeColor = $script:ColGris
})
$form.Controls.Add($btnAbortar)

# =============================================================================
# PANEL BOTONES FINALES (oculto inicialmente)
# =============================================================================
$pnlFinal = New-Object System.Windows.Forms.Panel
$pnlFinal.Location = New-Object System.Drawing.Point(20, 535)
$pnlFinal.Size = New-Object System.Drawing.Size(($formWidth - 40), 120)
$pnlFinal.BackColor = $script:ColFondo
$pnlFinal.Visible = $false
$form.Controls.Add($pnlFinal)

# Boton Volver al menu
$btnVolver = New-Object System.Windows.Forms.Button
$btnVolver.Text = (Get-Text "volver")
$btnVolver.Font = New-Object System.Drawing.Font($script:citaroFamily, 13)
$btnVolver.ForeColor = $script:ColCyan
$btnVolver.BackColor = $script:ColPanel
$btnVolver.FlatStyle = "Flat"
$btnVolver.FlatAppearance.BorderColor = $script:ColBorder
$btnVolver.FlatAppearance.BorderSize = 1
$btnVolver.FlatAppearance.MouseOverBackColor = $script:ColPanelHover
$btnVolver.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(20, 28, 45)
$btnVolver.Location = New-Object System.Drawing.Point(0, 5)
$btnVolver.Size = New-Object System.Drawing.Size(215, 50)
$btnVolver.Cursor = "Hand"
$btnVolver.Add_MouseEnter({
    $this.FlatAppearance.BorderColor = $script:ColBorderHover
    $this.FlatAppearance.BorderSize = 2
    $this.ForeColor = $script:ColCyanBright
})
$btnVolver.Add_MouseLeave({
    $this.FlatAppearance.BorderColor = $script:ColBorder
    $this.FlatAppearance.BorderSize = 1
    $this.ForeColor = $script:ColCyan
})
$btnVolver.Add_Click({
    $form.Hide()
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$LauncherScript`"" -WindowStyle Hidden
    $form.Close()
})
$pnlFinal.Controls.Add($btnVolver)

# Boton Salir
$btnSalirFinal = New-Object System.Windows.Forms.Button
$btnSalirFinal.Text = (Get-Text "salir")
$btnSalirFinal.Font = New-Object System.Drawing.Font($script:citaroFamily, 13)
$btnSalirFinal.ForeColor = $script:ColGris
$btnSalirFinal.BackColor = $script:ColPanel
$btnSalirFinal.FlatStyle = "Flat"
$btnSalirFinal.FlatAppearance.BorderColor = $script:ColGris
$btnSalirFinal.FlatAppearance.BorderSize = 1
$btnSalirFinal.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(35, 14, 16)
$btnSalirFinal.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(50, 18, 20)
$btnSalirFinal.Location = New-Object System.Drawing.Point(225, 5)
$btnSalirFinal.Size = New-Object System.Drawing.Size(215, 50)
$btnSalirFinal.Cursor = "Hand"
$btnSalirFinal.Add_MouseEnter({
    $this.FlatAppearance.BorderColor = $script:ColRojo
    $this.ForeColor = $script:ColRojo
})
$btnSalirFinal.Add_MouseLeave({
    $this.FlatAppearance.BorderColor = $script:ColGris
    $this.ForeColor = $script:ColGris
})
$btnSalirFinal.Add_Click({ $form.Close() })
$pnlFinal.Controls.Add($btnSalirFinal)

# Mensaje final
$lblFinalMsg = New-Object System.Windows.Forms.Label
$lblFinalMsg.Text = ""
$lblFinalMsg.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblFinalMsg.ForeColor = $script:ColVerde
$lblFinalMsg.Location = New-Object System.Drawing.Point(0, 65)
$lblFinalMsg.Size = New-Object System.Drawing.Size(($formWidth - 40), 45)
$lblFinalMsg.TextAlign = "MiddleCenter"
$pnlFinal.Controls.Add($lblFinalMsg)

# =============================================================================
# TIMER - Actualiza cada 100ms
# =============================================================================
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100

$spinnerChars = @([char]0x25DC, [char]0x25DD, [char]0x25DE, [char]0x25DF)  # Circulos rotando

$timer.Add_Tick({
    $elapsed = [DateTime]::Now - $script:TiempoInicio
    $lblTiempo.Text = "{0:mm\:ss}" -f $elapsed

    # Animacion spinner en etapa
    if (-not $script:Terminado) {
        $script:AnimFrame = ($script:AnimFrame + 1) % 4
        $spinner = $spinnerChars[$script:AnimFrame]
    }

    if (Test-Path $LogFile) {
        try {
            $json = Get-Content $LogFile -Raw -ErrorAction SilentlyContinue
            if ($json) {
                $data = $json | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($data) {
                    # Etapa con spinner
                    if ($data.Etapa -and -not $script:Terminado) {
                        $lblEtapa.Text = "$spinner " + $data.Etapa.ToUpper()
                    }

                    # Progreso
                    if ($null -ne $data.Progreso) {
                        $prog = [Math]::Min(100, [Math]::Max(0, $data.Progreso))
                        $lblPorcentaje.Text = "$prog%"
                        $pnlProgressBar.Tag.Progress = $prog
                        $pnlProgressBar.Invalidate()
                    }

                    # Tarea actual
                    if ($data.ArchivoActual -and $data.ArchivoActual -ne $script:UltimaTarea) {
                        $script:UltimaTarea = $data.ArchivoActual
                        $tarea = $data.ArchivoActual
                        if ($tarea.Length -gt 55) {
                            $tarea = $tarea.Substring(0, 52) + "..."
                        }
                        $lblTareaActual.Text = $tarea
                    }

                    # Contador tareas
                    if ($null -ne $data.ArchivosProcesados) {
                        $completadas = $data.ArchivosProcesados
                        $total = if ($data.TotalTareas) { $data.TotalTareas } else { 8 }
                        $lblTareas.Text = "$completadas/$total"
                    }

                    # Espacio liberado
                    if ($null -ne $data.EspacioLiberado) {
                        if ($data.EspacioLiberado -ge 1024) {
                            $lblEspacio.Text = "{0:N1} GB" -f ($data.EspacioLiberado / 1024)
                        } else {
                            $lblEspacio.Text = "{0:N0} MB" -f $data.EspacioLiberado
                        }
                    }

                    # Velocidad
                    if ($elapsed.TotalSeconds -gt 1 -and $data.ArchivosProcesados -gt 0) {
                        $velocidad = $data.ArchivosProcesados / $elapsed.TotalSeconds
                        $lblVelocidad.Text = "{0:N1} /s" -f $velocidad
                    }

                    # Log
                    if ($data.Log -and $data.Log -ne $script:UltimoLog) {
                        $script:UltimoLog = $data.Log
                        $ts = Get-Date -Format "HH:mm:ss"
                        $txtLog.AppendText("[$ts] $($data.Log)`r`n")
                        $txtLog.SelectionStart = $txtLog.Text.Length
                        $txtLog.ScrollToCaret()
                    }

                    # Completado
                    if ($data.Terminado -and -not $script:Terminado) {
                        $script:Terminado = $true

                        # Congelar tiempo al momento de completar
                        $lblTiempo.Text = "{0:mm\:ss}" -f $elapsed

                        # Actualizar contador final
                        if ($null -ne $data.ArchivosProcesados) {
                            $completadas = $data.ArchivosProcesados
                            $totalT = if ($data.TotalTareas) { $data.TotalTareas } else { 8 }
                            $lblTareas.Text = "$completadas/$totalT"
                        }

                        # Cambiar colores a verde
                        $pnlProgressBar.Tag.Completed = $true
                        $pnlProgressBar.Tag.Progress = 100
                        $pnlProgressBar.Invalidate()
                        $lblPorcentaje.ForeColor = $script:ColVerde
                        $lblPorcentaje.Text = "100%"
                        $lblEtapa.ForeColor = $script:ColVerde
                        $lblEtapa.Text = (Get-Text "completado")
                        $lblTareaActual.Text = (Get-Text "tareasFinalizadas")
                        $lblTareaActual.ForeColor = $script:ColVerde

                        # Ocultar abortar, mostrar botones finales
                        $btnAbortar.Visible = $false
                        $pnlFinal.Visible = $true

                        # Mensaje final con espacio y tiempo
                        $espacio = if ($data.EspacioLiberado -ge 1024) { "{0:N1} GB" -f ($data.EspacioLiberado / 1024) } else { "{0:N0} MB" -f $data.EspacioLiberado }
                        $lblFinalMsg.Text = "$espacio $(Get-Text 'liberadosEn') {0:mm\:ss}" -f $elapsed

                        # Log final
                        $ts = Get-Date -Format "HH:mm:ss"
                        $txtLog.AppendText("[$ts] $(Get-Text 'completadoMsg') $espacio $(Get-Text 'liberadosEn') {0:mm\:ss}`r`n" -f $elapsed)

                        # Sonido de Nala (ladrido)
                        if (Test-Path $SoundPath) {
                            try {
                                $player = New-Object System.Media.SoundPlayer($SoundPath)
                                $player.Play()
                            } catch {}
                        }

                        # Parar timer (congela reloj y evita parpadeo barra)
                        $timer.Stop()
                    }
                }
            }
        } catch { }
    }
})

# =============================================================================
# EVENTOS DE VENTANA
# =============================================================================
$form.Add_Shown({
    $timer.Start()
    $ts = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$ts] $(Get-Text 'monitorIniciado')`r`n")
    if (Test-Path $AbortFile) { Remove-Item $AbortFile -Force }
})

$form.Add_FormClosing({
    $timer.Stop()
    if (Test-Path $AbortFile) { Remove-Item $AbortFile -Force }
    # Limpiar archivo de progreso
    if (Test-Path $LogFile) { Remove-Item $LogFile -Force -ErrorAction SilentlyContinue }
})

# Teclas de atajo
$form.Add_KeyDown({
    param($sender, $e)
    if ($script:Terminado) {
        if ($e.KeyCode -eq "V") { $btnVolver.PerformClick() }
        if ($e.KeyCode -eq "X" -or $e.KeyCode -eq "Escape") { $btnSalirFinal.PerformClick() }
    } else {
        if ($e.KeyCode -eq "Escape") { $btnAbortar.PerformClick() }
    }
})
$form.KeyPreview = $true

[void]$form.ShowDialog()
