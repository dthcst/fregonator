<#
    FREGONATOR LAUNCHER v6.0
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

# ============================================================================
# SINGLETON - Solo una instancia del Launcher
# ============================================================================
$script:FregMutex = New-Object System.Threading.Mutex($false, "Global\FREGONATOR_LAUNCHER_v5")
if (-not $script:FregMutex.WaitOne(0)) {
    $resp = [System.Windows.Forms.MessageBox]::Show(
        "FREGONATOR ya esta abierto.`n`nCerrar la instancia anterior?",
        "FREGONATOR",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($resp -eq "Yes") {
        # Cerrar instancias anteriores del Launcher
        $myPid = $PID
        Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
            $_.Id -ne $myPid -and $_.MainWindowTitle -eq "FREGONATOR"
        } | ForEach-Object { $_.CloseMainWindow(); Start-Sleep -Milliseconds 300; if (-not $_.HasExited) { $_.Kill() } }
        Start-Sleep -Milliseconds 500
        # Reintentar mutex
        $script:FregMutex = New-Object System.Threading.Mutex($false, "Global\FREGONATOR_LAUNCHER_v5")
        $null = $script:FregMutex.WaitOne(2000)
    } else {
        $script:FregMutex.Dispose()
        exit
    }
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
        if ($saved -eq "en" -or $saved -eq "es") { return $saved }
    }

    # Auto-detectar del sistema
    $uiCulture = (Get-UICulture).Name
    $culture = (Get-Culture).Name
    foreach ($lang in @($uiCulture, $culture)) {
        if ($lang -like "en*") { return "en" }
        if ($lang -like "es*") { return "es" }
        if ($lang -like "gl*") { return "es" }
    }
    return "en"  # Default internacional
}

$script:Lang = Get-SystemLanguage

$script:Texts = @{
    es = @{
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
        version = "v6.0"
    }
    en = @{
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
        version = "v6.0"
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
    if ($script:SoundEnabled -and $script:SoundPlayer) {
        try { $script:SoundPlayer.Play() } catch {}
    }
}

# Funcion para sonido hover tipo "fregona-sable" (swoosh ascendente)
function Play-HoverSound {
    if (-not $script:SoundEnabled) { return }
    try {
        [Console]::Beep(500, 30)
    } catch {}
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
# COLORES - Paleta Tron Legacy (v6.0)
# ============================================================================
$script:ColFondo       = [System.Drawing.Color]::FromArgb(6, 8, 14)
$script:ColBoton       = [System.Drawing.Color]::FromArgb(12, 16, 26)
$script:ColCyan        = [System.Drawing.Color]::FromArgb(0, 232, 255)
$script:ColCyanBright  = [System.Drawing.Color]::FromArgb(102, 240, 255)
$script:ColCyanDark    = [System.Drawing.Color]::FromArgb(0, 160, 180)
$script:ColCyanDim     = [System.Drawing.Color]::FromArgb(0, 80, 100)
$script:ColGris        = [System.Drawing.Color]::FromArgb(55, 62, 75)
$script:ColNegro       = [System.Drawing.Color]::FromArgb(4, 6, 12)
$script:ColRojo        = [System.Drawing.Color]::FromArgb(255, 70, 70)
$script:ColVerde       = [System.Drawing.Color]::FromArgb(0, 230, 120)
$script:ColGlow        = [System.Drawing.Color]::FromArgb(25, 0, 200, 255)
$script:ColBorder      = [System.Drawing.Color]::FromArgb(0, 120, 140)
$script:ColBorderHover = [System.Drawing.Color]::FromArgb(0, 232, 255)
$script:ColPanelHover  = [System.Drawing.Color]::FromArgb(16, 22, 36)
$script:ColGridLine    = [System.Drawing.Color]::FromArgb(15, 20, 32)

# ============================================================================
# VENTANA PRINCIPAL - Centrada manualmente
# ============================================================================
$formWidth = 540
$formHeight = 600

$form = New-Object System.Windows.Forms.Form
$form.Text = "FREGONATOR"
$form.Size = New-Object System.Drawing.Size($formWidth, $formHeight)
$form.BackColor = $script:ColFondo
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$iconPath = Join-Path $script:ScriptPath "fregonator.ico"
if (Test-Path $iconPath) { $form.Icon = New-Object System.Drawing.Icon($iconPath) }

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
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Location = New-Object System.Drawing.Point(0, 0)
$pnlHeader.Size = New-Object System.Drawing.Size($formWidth, 115)
$pnlHeader.BackColor = $script:ColFondo

$pnlHeader.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $w = $sender.Width

    # "FREGONATOR" en SAM font grande, centrado
    $fTitle = New-Object System.Drawing.Font($script:samFamily, 36)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = "Center"
    $titleY = 12

    # Glow multi-pase (mas visible)
    for ($i = 4; $i -ge 1; $i--) {
        $alpha = [int](12 + (4 - $i) * 4)
        $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 0, 180, 255))
        $g.DrawString("FREGONATOR", $fTitle, $glowBrush, ($w / 2), ($titleY - $i), $sf)
        $g.DrawString("FREGONATOR", $fTitle, $glowBrush, ($w / 2), ($titleY + $i), $sf)
        $g.DrawString("FREGONATOR", $fTitle, $glowBrush, (($w / 2) - $i), $titleY, $sf)
        $g.DrawString("FREGONATOR", $fTitle, $glowBrush, (($w / 2) + $i), $titleY, $sf)
    }
    # Texto principal
    $g.DrawString("FREGONATOR", $fTitle, (New-Object System.Drawing.SolidBrush($script:ColCyan)), ($w / 2), $titleY, $sf)

    # Subtitulo
    $fSub = New-Object System.Drawing.Font("Segoe UI", 9)
    $g.DrawString("OPTIMIZADOR DE PC", $fSub, (New-Object System.Drawing.SolidBrush($script:ColCyanDim)), ($w / 2), 68, $sf)

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
$pnlHeader.Controls.Add($btnLangH)

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
$pnlHeader.Controls.Add($btnSoundH)

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
        $fAtajo = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)

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

$btn1 = New-GlowButton -Titulo (Get-Text "limpiezaRapida") -Descripcion (Get-Text "descRapida") -Atajo "[1]" -Y 132 -OnClick {
    Start-FregonatorDual -Modo "-AutoRapida"
}
$form.Controls.Add($btn1)

# ============================================================================
# BOTON 2 - LIMPIEZA COMPLETA
# ============================================================================
$btn2 = New-GlowButton -Titulo (Get-Text "limpiezaCompleta") -Descripcion (Get-Text "descCompleta") -Atajo "[2]" -Y 232 -OnClick {
    Start-FregonatorDual -Modo "-AutoAvanzada"
}
$form.Controls.Add($btn2)

# ============================================================================
# BOTON 3 - MENU TERMINAL MS-DOS
# ============================================================================
$btn3 = New-GlowButton -Titulo (Get-Text "terminal") -Descripcion (Get-Text "descTerminal") -Atajo "[3]" -Y 332 -OnClick {
    $form.Hide()
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$script:FregonatorScript`"" -Verb RunAs
    $form.Close()
}
$form.Controls.Add($btn3)

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
        if ($nextRun) { "ACTIVO - Proxima: $($nextRun.ToString('dd/MM HH:mm'))" } else { "ACTIVO" }
    } else { "NO CONFIGURADO" }

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
    $lblTitulo.Text = "PROGRAMAR LIMPIEZA"
    $lblTitulo.Font = New-Object System.Drawing.Font($script:citaroFamily, 16)
    $lblTitulo.ForeColor = $script:ColCyan
    $lblTitulo.Location = New-Object System.Drawing.Point(30, 20)
    $lblTitulo.AutoSize = $true
    $dlg.Controls.Add($lblTitulo)

    # Estado actual
    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = "Estado: $statusText"
    $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblStatus.ForeColor = if ($existingTask) { $script:ColVerde } else { [System.Drawing.Color]::Gray }
    $lblStatus.Location = New-Object System.Drawing.Point(30, 55)
    $lblStatus.AutoSize = $true
    $dlg.Controls.Add($lblStatus)

    # Frecuencia
    $lblFreq = New-Object System.Windows.Forms.Label
    $lblFreq.Text = "Frecuencia:"
    $lblFreq.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblFreq.ForeColor = $script:ColCyanDark
    $lblFreq.Location = New-Object System.Drawing.Point(30, 95)
    $lblFreq.AutoSize = $true
    $dlg.Controls.Add($lblFreq)

    $cmbFreq = New-Object System.Windows.Forms.ComboBox
    $cmbFreq.Items.AddRange(@("Diaria (recomendado)", "Semanal", "Al iniciar sesion"))
    $cmbFreq.SelectedIndex = 0
    $cmbFreq.Location = New-Object System.Drawing.Point(130, 92)
    $cmbFreq.Size = New-Object System.Drawing.Size(220, 25)
    $cmbFreq.DropDownStyle = "DropDownList"
    $cmbFreq.BackColor = $script:ColBoton
    $cmbFreq.ForeColor = [System.Drawing.Color]::White
    $dlg.Controls.Add($cmbFreq)

    # Hora
    $lblHora = New-Object System.Windows.Forms.Label
    $lblHora.Text = "Hora:"
    $lblHora.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblHora.ForeColor = $script:ColCyanDark
    $lblHora.Location = New-Object System.Drawing.Point(30, 135)
    $lblHora.AutoSize = $true
    $dlg.Controls.Add($lblHora)

    $cmbHora = New-Object System.Windows.Forms.ComboBox
    $cmbHora.Items.AddRange(@("03:00 (recomendado)", "04:00", "05:00", "06:00", "12:00", "22:00", "23:00"))
    $cmbHora.SelectedIndex = 0
    $cmbHora.Location = New-Object System.Drawing.Point(130, 132)
    $cmbHora.Size = New-Object System.Drawing.Size(220, 25)
    $cmbHora.DropDownStyle = "DropDownList"
    $cmbHora.BackColor = $script:ColBoton
    $cmbHora.ForeColor = [System.Drawing.Color]::White
    $dlg.Controls.Add($cmbHora)

    # Info
    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = "La limpieza se ejecutara en segundo plano`nusando el modo silencioso (sin ventanas)."
    $lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lblInfo.ForeColor = [System.Drawing.Color]::Gray
    $lblInfo.Location = New-Object System.Drawing.Point(30, 175)
    $lblInfo.Size = New-Object System.Drawing.Size(320, 40)
    $dlg.Controls.Add($lblInfo)

    # Boton ACTIVAR
    $btnActivar = New-Object System.Windows.Forms.Button
    $btnActivar.Text = "ACTIVAR"
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

            [System.Windows.Forms.MessageBox]::Show("Tarea programada creada correctamente.`n`nFrecuencia: $($cmbFreq.SelectedItem)`nHora: $hora", "FREGONATOR", "OK", "Information")
            $dlg.Close()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error: Ejecuta FREGONATOR como Administrador.`n`n$_", "Error", "OK", "Error")
        }
    })
    $dlg.Controls.Add($btnActivar)

    # Boton DESACTIVAR
    $btnDesactivar = New-Object System.Windows.Forms.Button
    $btnDesactivar.Text = "DESACTIVAR"
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
            [System.Windows.Forms.MessageBox]::Show("Tarea programada eliminada.", "FREGONATOR", "OK", "Information")
            $dlg.Close()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("No hay tarea programada activa.", "FREGONATOR", "OK", "Warning")
        }
    })
    $dlg.Controls.Add($btnDesactivar)

    # Boton CERRAR
    $btnCerrar = New-Object System.Windows.Forms.Button
    $btnCerrar.Text = "CERRAR"
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
$form.Controls.Add($btnSalir)

# ============================================================================
# EVENTO CLICK IDIOMA (referencia a $btnLangH dentro del header)
# ============================================================================
$btnLangH.Add_Click({
    # Toggle idioma
    $script:Lang = if ($script:Lang -eq "es") { "en" } else { "es" }
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
$pnlFooter = New-Object System.Windows.Forms.Panel
$pnlFooter.Location = New-Object System.Drawing.Point(0, 510)
$pnlFooter.Size = New-Object System.Drawing.Size($formWidth, 30)
$pnlFooter.BackColor = $script:ColFondo
$pnlFooter.Cursor = "Default"

# Track hover zones para links clickeables
$pnlFooter.Tag = @{ HoverZone = ""; Zones = @() }

$pnlFooter.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $w = $sender.Width

    $fFont = New-Object System.Drawing.Font("Segoe UI", 8)
    $fConsolaFont = New-Object System.Drawing.Font("Consolas", 8)
    $dimBrush = New-Object System.Drawing.SolidBrush($footerDim)
    $sepBrush = New-Object System.Drawing.SolidBrush($script:ColGridLine)
    $cyanBrush = New-Object System.Drawing.SolidBrush($script:ColCyan)

    $parts = @(
        @{ Text = "v6.0"; Font = $fConsolaFont; Brush = $dimBrush; Link = "" },
        @{ Text = "  |  "; Font = $fFont; Brush = $sepBrush; Link = "" },
        @{ Text = "fregonator.com"; Font = $fFont; Brush = $dimBrush; Link = "https://fregonator.com" },
        @{ Text = "  |  "; Font = $fFont; Brush = $sepBrush; Link = "" },
        @{ Text = "costa-da-morte.com"; Font = $fFont; Brush = $dimBrush; Link = "https://costa-da-morte.com" }
    )

    # Medir ancho total
    $totalW = 0
    foreach ($p in $parts) { $totalW += [int]($g.MeasureString($p.Text, $p.Font).Width) }
    $startX = [int](($w - $totalW) / 2)
    $y = 6
    $curX = $startX

    $zones = @()
    $hoverZone = $sender.Tag.HoverZone

    foreach ($p in $parts) {
        $sz = $g.MeasureString($p.Text, $p.Font)
        $brush = $p.Brush
        if ($p.Link -ne "" -and $hoverZone -eq $p.Link) { $brush = $cyanBrush }
        $g.DrawString($p.Text, $p.Font, $brush, $curX, $y)
        if ($p.Link -ne "") {
            $zones += @{ X1 = [int]$curX; X2 = [int]($curX + $sz.Width); Link = $p.Link }
        }
        $curX += [int]$sz.Width
    }
    $sender.Tag.Zones = $zones
})

$pnlFooter.Add_MouseMove({
    param($sender, $e)
    $mx = $e.X
    $newZone = ""
    foreach ($z in $sender.Tag.Zones) {
        if ($mx -ge $z.X1 -and $mx -le $z.X2) { $newZone = $z.Link; break }
    }
    if ($newZone -ne $sender.Tag.HoverZone) {
        $sender.Tag.HoverZone = $newZone
        $sender.Cursor = if ($newZone -ne "") { [System.Windows.Forms.Cursors]::Hand } else { [System.Windows.Forms.Cursors]::Default }
        $sender.Invalidate()
    }
})

$pnlFooter.Add_MouseLeave({
    $this.Tag.HoverZone = ""
    $this.Cursor = [System.Windows.Forms.Cursors]::Default
    $this.Invalidate()
})

$pnlFooter.Add_Click({
    param($sender, $e)
    $mx = $e.X
    foreach ($z in $sender.Tag.Zones) {
        if ($mx -ge $z.X1 -and $mx -le $z.X2) { Start-Process $z.Link; break }
    }
})

$form.Controls.Add($pnlFooter)

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
    Play-Bark
})

# ============================================================================
# MOSTRAR
# ============================================================================
[void]$form.ShowDialog()

# Liberar mutex al cerrar
try { $script:FregMutex.ReleaseMutex() } catch {}
$script:FregMutex.Dispose()
