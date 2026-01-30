<#
    FREGONATOR MONITOR v3.5.2
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
Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null  # 0 = SW_HIDE

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogoPath = Join-Path $ScriptPath "Logo-Fregonator-001.png"
$FontPath = Join-Path $ScriptPath "_FUENTES\citaro_voor_dubbele_hoogte_breed\citaro_voor_dubbele_hoogte_breed.ttf"
$AbortFile = "$env:PUBLIC\fregonator_abort.flag"
$LauncherScript = Join-Path $ScriptPath "Fregonator-Launcher.ps1"
$SoundPath = Join-Path $ScriptPath "sounds\bark.wav"

# Cargar fuente Citaro
$script:privateFonts = New-Object System.Drawing.Text.PrivateFontCollection
if (Test-Path $FontPath) {
    $script:privateFonts.AddFontFile($FontPath)
    $script:citaroFamily = $script:privateFonts.Families[0]
} else {
    $script:citaroFamily = [System.Drawing.FontFamily]::GenericMonospace
}

# =============================================================================
# PALETA DE COLORES - Estilo Daft Punk / Tron
# =============================================================================
$script:ColFondo     = [System.Drawing.Color]::FromArgb(8, 8, 12)
$script:ColPanel     = [System.Drawing.Color]::FromArgb(15, 15, 20)
$script:ColCyan      = [System.Drawing.Color]::FromArgb(0, 255, 255)
$script:ColCyanDark  = [System.Drawing.Color]::FromArgb(0, 180, 180)
$script:ColCyanDim   = [System.Drawing.Color]::FromArgb(0, 100, 100)
$script:ColGris      = [System.Drawing.Color]::FromArgb(80, 80, 90)
$script:ColGrisOsc   = [System.Drawing.Color]::FromArgb(25, 25, 30)
$script:ColVerde     = [System.Drawing.Color]::FromArgb(0, 255, 120)
$script:ColAmarillo  = [System.Drawing.Color]::FromArgb(255, 220, 0)
$script:ColRojo      = [System.Drawing.Color]::FromArgb(255, 80, 80)
$script:ColNaranja   = [System.Drawing.Color]::FromArgb(255, 150, 50)

# Estado global
$script:TiempoInicio = [DateTime]::Now
$script:UltimoLog = ""
$script:Terminado = $false
$script:UltimaTarea = ""
$script:TareasCompletadas = @()
$script:AnimFrame = 0

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

# Posicionar a la DERECHA de la pantalla
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.StartPosition = "Manual"
$form.Location = New-Object System.Drawing.Point(
    [int]($screen.Width - $formWidth - 20),  # Derecha con margen
    [int](($screen.Height - $formHeight) / 2) # Centrado vertical
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
$form.Controls.Add($pnlTitulo)

# Icono y titulo
$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text = "FREGONATOR MONITOR"
$lblTitulo.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$lblTitulo.ForeColor = $script:ColCyan
$lblTitulo.Location = New-Object System.Drawing.Point(12, 6)
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
$lblEtapa.Text = "> INICIANDO..."
$lblEtapa.Font = New-Object System.Drawing.Font($script:citaroFamily, 14)
$lblEtapa.ForeColor = $script:ColCyan
$lblEtapa.BackColor = $script:ColFondo
$lblEtapa.Location = New-Object System.Drawing.Point(20, 100)
$lblEtapa.Size = New-Object System.Drawing.Size(($formWidth - 40), 28)
$form.Controls.Add($lblEtapa)

# =============================================================================
# BARRA DE PROGRESO PRINCIPAL
# =============================================================================
$pnlProgressContainer = New-Object System.Windows.Forms.Panel
$pnlProgressContainer.Location = New-Object System.Drawing.Point(20, 135)
$pnlProgressContainer.Size = New-Object System.Drawing.Size(($formWidth - 40), 32)
$pnlProgressContainer.BackColor = $script:ColGrisOsc

$pnlProgress = New-Object System.Windows.Forms.Panel
$pnlProgress.Location = New-Object System.Drawing.Point(2, 2)
$pnlProgress.Size = New-Object System.Drawing.Size(0, 28)
$pnlProgress.BackColor = $script:ColCyan
$pnlProgressContainer.Controls.Add($pnlProgress)
$form.Controls.Add($pnlProgressContainer)

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
# PANEL ESTADISTICAS
# =============================================================================
$pnlStats = New-Object System.Windows.Forms.Panel
$pnlStats.Location = New-Object System.Drawing.Point(20, 245)
$pnlStats.Size = New-Object System.Drawing.Size(($formWidth - 40), 75)
$pnlStats.BackColor = $script:ColPanel
$form.Controls.Add($pnlStats)

# Tareas
$lblTareasIcon = New-Object System.Windows.Forms.Label
$lblTareasIcon.Text = "TAREAS"
$lblTareasIcon.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblTareasIcon.ForeColor = $script:ColGris
$lblTareasIcon.Location = New-Object System.Drawing.Point(20, 8)
$lblTareasIcon.AutoSize = $true
$pnlStats.Controls.Add($lblTareasIcon)

$lblTareas = New-Object System.Windows.Forms.Label
$lblTareas.Text = "0/8"
$lblTareas.Font = New-Object System.Drawing.Font($script:citaroFamily, 22)
$lblTareas.ForeColor = $script:ColCyan
$lblTareas.Location = New-Object System.Drawing.Point(15, 30)
$lblTareas.Size = New-Object System.Drawing.Size(100, 38)
$pnlStats.Controls.Add($lblTareas)

# Espacio liberado
$lblEspacioIcon = New-Object System.Windows.Forms.Label
$lblEspacioIcon.Text = "LIBERADO"
$lblEspacioIcon.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblEspacioIcon.ForeColor = $script:ColGris
$lblEspacioIcon.Location = New-Object System.Drawing.Point(160, 8)
$lblEspacioIcon.AutoSize = $true
$pnlStats.Controls.Add($lblEspacioIcon)

$lblEspacio = New-Object System.Windows.Forms.Label
$lblEspacio.Text = "0 MB"
$lblEspacio.Font = New-Object System.Drawing.Font($script:citaroFamily, 22)
$lblEspacio.ForeColor = $script:ColVerde
$lblEspacio.Location = New-Object System.Drawing.Point(155, 30)
$lblEspacio.Size = New-Object System.Drawing.Size(150, 38)
$pnlStats.Controls.Add($lblEspacio)

# Velocidad
$lblVelocidadIcon = New-Object System.Windows.Forms.Label
$lblVelocidadIcon.Text = "VELOCIDAD"
$lblVelocidadIcon.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblVelocidadIcon.ForeColor = $script:ColGris
$lblVelocidadIcon.Location = New-Object System.Drawing.Point(330, 8)
$lblVelocidadIcon.AutoSize = $true
$pnlStats.Controls.Add($lblVelocidadIcon)

$lblVelocidad = New-Object System.Windows.Forms.Label
$lblVelocidad.Text = "-- /s"
$lblVelocidad.Font = New-Object System.Drawing.Font($script:citaroFamily, 18)
$lblVelocidad.ForeColor = $script:ColAmarillo
$lblVelocidad.Location = New-Object System.Drawing.Point(325, 32)
$lblVelocidad.Size = New-Object System.Drawing.Size(100, 35)
$pnlStats.Controls.Add($lblVelocidad)

# =============================================================================
# TAREA ACTUAL - Mas prominente
# =============================================================================
$lblTareaLabel = New-Object System.Windows.Forms.Label
$lblTareaLabel.Text = "PROCESANDO:"
$lblTareaLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$lblTareaLabel.ForeColor = $script:ColCyanDim
$lblTareaLabel.Location = New-Object System.Drawing.Point(20, 330)
$lblTareaLabel.AutoSize = $true
$form.Controls.Add($lblTareaLabel)

$lblTareaActual = New-Object System.Windows.Forms.Label
$lblTareaActual.Text = "Esperando inicio..."
$lblTareaActual.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$lblTareaActual.ForeColor = $script:ColCyan
$lblTareaActual.BackColor = $script:ColPanel
$lblTareaActual.Location = New-Object System.Drawing.Point(20, 350)
$lblTareaActual.Size = New-Object System.Drawing.Size(($formWidth - 40), 28)
$lblTareaActual.Padding = New-Object System.Windows.Forms.Padding(8, 5, 8, 5)
$form.Controls.Add($lblTareaActual)

# =============================================================================
# LOG DE ACTIVIDAD
# =============================================================================
$lblLogLabel = New-Object System.Windows.Forms.Label
$lblLogLabel.Text = "ACTIVIDAD:"
$lblLogLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$lblLogLabel.ForeColor = $script:ColCyanDim
$lblLogLabel.Location = New-Object System.Drawing.Point(20, 388)
$lblLogLabel.AutoSize = $true
$form.Controls.Add($lblLogLabel)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.ForeColor = $script:ColCyanDark
$txtLog.BackColor = $script:ColPanel
$txtLog.BorderStyle = "None"
$txtLog.Location = New-Object System.Drawing.Point(20, 408)
$txtLog.Size = New-Object System.Drawing.Size(($formWidth - 40), 115)
$form.Controls.Add($txtLog)

# =============================================================================
# BOTON ABORTAR (se oculta al terminar)
# =============================================================================
$btnAbortar = New-Object System.Windows.Forms.Button
$btnAbortar.Text = "ABORTAR"
$btnAbortar.Font = New-Object System.Drawing.Font($script:citaroFamily, 14)
$btnAbortar.ForeColor = $script:ColRojo
$btnAbortar.BackColor = $script:ColPanel
$btnAbortar.FlatStyle = "Flat"
$btnAbortar.FlatAppearance.BorderColor = $script:ColRojo
$btnAbortar.FlatAppearance.BorderSize = 2
$btnAbortar.FlatAppearance.MouseOverBackColor = $script:ColRojo
$btnAbortar.Location = New-Object System.Drawing.Point(20, 535)
$btnAbortar.Size = New-Object System.Drawing.Size(($formWidth - 40), 50)
$btnAbortar.Cursor = "Hand"
$btnAbortar.Add_MouseEnter({ $this.ForeColor = [System.Drawing.Color]::White })
$btnAbortar.Add_MouseLeave({ $this.ForeColor = $script:ColRojo })
$btnAbortar.Add_Click({
    "ABORT" | Out-File $AbortFile -Force
    $ts = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$ts] ABORTANDO...`r`n")
    $this.Enabled = $false
    $this.Text = "ABORTANDO..."
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
$btnVolver.Text = "[V] VOLVER AL MENU"
$btnVolver.Font = New-Object System.Drawing.Font($script:citaroFamily, 13)
$btnVolver.ForeColor = $script:ColCyan
$btnVolver.BackColor = $script:ColPanel
$btnVolver.FlatStyle = "Flat"
$btnVolver.FlatAppearance.BorderColor = $script:ColCyan
$btnVolver.FlatAppearance.BorderSize = 2
$btnVolver.FlatAppearance.MouseOverBackColor = $script:ColCyan
$btnVolver.Location = New-Object System.Drawing.Point(0, 5)
$btnVolver.Size = New-Object System.Drawing.Size(215, 50)
$btnVolver.Cursor = "Hand"
$btnVolver.Add_MouseEnter({ $this.ForeColor = [System.Drawing.Color]::Black })
$btnVolver.Add_MouseLeave({ $this.ForeColor = $script:ColCyan })
$btnVolver.Add_Click({
    $form.Hide()
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$LauncherScript`""
    $form.Close()
})
$pnlFinal.Controls.Add($btnVolver)

# Boton Salir
$btnSalirFinal = New-Object System.Windows.Forms.Button
$btnSalirFinal.Text = "[X] SALIR"
$btnSalirFinal.Font = New-Object System.Drawing.Font($script:citaroFamily, 13)
$btnSalirFinal.ForeColor = $script:ColGris
$btnSalirFinal.BackColor = $script:ColPanel
$btnSalirFinal.FlatStyle = "Flat"
$btnSalirFinal.FlatAppearance.BorderColor = $script:ColGris
$btnSalirFinal.FlatAppearance.BorderSize = 2
$btnSalirFinal.FlatAppearance.MouseOverBackColor = $script:ColRojo
$btnSalirFinal.Location = New-Object System.Drawing.Point(225, 5)
$btnSalirFinal.Size = New-Object System.Drawing.Size(215, 50)
$btnSalirFinal.Cursor = "Hand"
$btnSalirFinal.Add_MouseEnter({ $this.ForeColor = [System.Drawing.Color]::White })
$btnSalirFinal.Add_MouseLeave({ $this.ForeColor = $script:ColGris })
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
                        $barWidth = [int](($prog / 100) * 436)
                        $pnlProgress.Size = New-Object System.Drawing.Size($barWidth, 28)
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

                        # Cambiar colores a verde
                        $pnlProgress.BackColor = $script:ColVerde
                        $lblPorcentaje.ForeColor = $script:ColVerde
                        $lblPorcentaje.Text = "100%"
                        $lblEtapa.ForeColor = $script:ColVerde
                        $lblEtapa.Text = "LIMPIEZA COMPLETADA!"
                        $lblTareaActual.Text = "Todas las tareas finalizadas"
                        $lblTareaActual.ForeColor = $script:ColVerde

                        # Ocultar abortar, mostrar botones finales
                        $btnAbortar.Visible = $false
                        $pnlFinal.Visible = $true

                        # Mensaje final con espacio y tiempo
                        $espacio = if ($data.EspacioLiberado -ge 1024) { "{0:N1} GB" -f ($data.EspacioLiberado / 1024) } else { "{0:N0} MB" -f $data.EspacioLiberado }
                        $lblFinalMsg.Text = "$espacio liberados en {0:mm\:ss}" -f $elapsed

                        # Log final
                        $ts = Get-Date -Format "HH:mm:ss"
                        $txtLog.AppendText("[$ts] COMPLETADO: $espacio liberados en {0:mm\:ss}`r`n" -f $elapsed)

                        # Sonido de Nala (ladrido)
                        if (Test-Path $SoundPath) {
                            try {
                                $player = New-Object System.Media.SoundPlayer($SoundPath)
                                $player.Play()
                            } catch {}
                        }
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
    $txtLog.AppendText("[$ts] Monitor iniciado - Esperando datos...`r`n")
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
