<#
    FREGONATOR LAUNCHER v3.5.2
    Menu principal con efecto Glow + Sonidos
    - Oculto de barra de tareas
    2026
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================================
# RUTAS (scope script para acceso en eventos)
# ============================================================================
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:FregonatorScript = Join-Path $script:ScriptPath "Fregonator.ps1"
$script:MonitorScript = Join-Path $script:ScriptPath "Fregonator-Monitor.ps1"
$script:LogoPath = Join-Path $script:ScriptPath "Logo-Fregonator-001.png"
$script:FontPath = Join-Path $script:ScriptPath "_FUENTES\citaro_voor_dubbele_hoogte_breed\citaro_voor_dubbele_hoogte_breed.ttf"
$script:ProgressFile = "$env:PUBLIC\fregonator_progress.json"
$script:BarkSound = Join-Path $script:ScriptPath "_SONIDOS\bark.wav"

# ============================================================================
# SONIDOS - Ladrido de Nala + Swoosh fregona-sable
# ============================================================================
$script:SoundPlayer = $null
if (Test-Path $script:BarkSound) {
    $script:SoundPlayer = New-Object System.Media.SoundPlayer($script:BarkSound)
}

# Funcion para sonido hover tipo "fregona-sable" (swoosh ascendente)
function Play-HoverSound {
    # Swoosh rapido: frecuencia sube de 400 a 800 Hz en 50ms
    try {
        [Console]::Beep(500, 30)
    } catch {}
}

# ============================================================================
# CARGAR FUENTE CITARO (scope script)
# ============================================================================
$script:privateFonts = New-Object System.Drawing.Text.PrivateFontCollection
if (Test-Path $script:FontPath) {
    $script:privateFonts.AddFontFile($script:FontPath)
    $script:citaroFamily = $script:privateFonts.Families[0]
} else {
    $script:citaroFamily = [System.Drawing.FontFamily]::GenericMonospace
}

# ============================================================================
# COLORES - Paleta Daft Punk / Tron
# ============================================================================
$script:ColFondo    = [System.Drawing.Color]::FromArgb(8, 8, 12)
$script:ColBoton    = [System.Drawing.Color]::FromArgb(15, 15, 20)
$script:ColCyan     = [System.Drawing.Color]::FromArgb(0, 255, 255)
$script:ColCyanDark = [System.Drawing.Color]::FromArgb(0, 180, 180)
$script:ColGris     = [System.Drawing.Color]::FromArgb(80, 80, 90)
$script:ColNegro    = [System.Drawing.Color]::FromArgb(10, 10, 10)
$script:ColRojo     = [System.Drawing.Color]::FromArgb(255, 80, 80)
$script:ColVerde    = [System.Drawing.Color]::FromArgb(0, 255, 120)
$script:ColGlow     = [System.Drawing.Color]::FromArgb(35, 0, 255, 255)

# ============================================================================
# VENTANA PRINCIPAL - Centrada manualmente
# ============================================================================
$formWidth = 520
$formHeight = 560

$form = New-Object System.Windows.Forms.Form
$form.Text = "FREGONATOR"
$form.Size = New-Object System.Drawing.Size($formWidth, $formHeight)
$form.BackColor = $script:ColFondo
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# Centrar manualmente en pantalla
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.StartPosition = "Manual"
$form.Location = New-Object System.Drawing.Point(
    [int](($screen.Width - $formWidth) / 2),
    [int](($screen.Height - $formHeight) / 2)
)

# ============================================================================
# LOGO
# ============================================================================
if (Test-Path $script:LogoPath) {
    $picLogo = New-Object System.Windows.Forms.PictureBox
    $picLogo.Image = [System.Drawing.Image]::FromFile($script:LogoPath)
    $picLogo.SizeMode = "Zoom"
    $picLogo.Location = New-Object System.Drawing.Point(40, 20)
    $picLogo.Size = New-Object System.Drawing.Size(420, 100)
    $picLogo.BackColor = $script:ColFondo
    $form.Controls.Add($picLogo)
}

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
    $btn.FlatAppearance.BorderSize = 2
    $btn.FlatAppearance.BorderColor = $script:ColCyan
    $btn.FlatAppearance.MouseOverBackColor = $script:ColCyan
    $btn.FlatAppearance.MouseDownBackColor = $script:ColCyan
    $btn.BackColor = $script:ColBoton
    $btn.Location = New-Object System.Drawing.Point(40, $Y)
    $btn.Size = New-Object System.Drawing.Size(420, 85)
    $btn.Cursor = "Hand"
    $btn.Tag = @{Titulo = $Titulo; Desc = $Descripcion; Atajo = $Atajo; Hover = $false}

    $btn.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

        $fTitulo = New-Object System.Drawing.Font($script:citaroFamily, 18)
        $fDesc = New-Object System.Drawing.Font("Segoe UI", 9)
        $fAtajo = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)

        if ($sender.Tag.Hover) {
            $g.DrawString($sender.Tag.Titulo, $fTitulo, (New-Object System.Drawing.SolidBrush($script:ColNegro)), 20, 15)
            $g.DrawString($sender.Tag.Desc, $fDesc, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 60, 60))), 20, 48)
            $g.DrawString($sender.Tag.Atajo, $fAtajo, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 60, 60))), 360, 58)
        } else {
            # Glow effect
            $glowBrush = New-Object System.Drawing.SolidBrush($script:ColGlow)
            for ($i = 3; $i -ge 1; $i--) {
                $g.DrawString($sender.Tag.Titulo, $fTitulo, $glowBrush, (20 - $i), (15 - $i))
                $g.DrawString($sender.Tag.Titulo, $fTitulo, $glowBrush, (20 + $i), (15 + $i))
            }
            $g.DrawString($sender.Tag.Titulo, $fTitulo, (New-Object System.Drawing.SolidBrush($script:ColCyan)), 20, 15)
            $g.DrawString($sender.Tag.Desc, $fDesc, (New-Object System.Drawing.SolidBrush($script:ColCyanDark)), 20, 48)
            $g.DrawString($sender.Tag.Atajo, $fAtajo, (New-Object System.Drawing.SolidBrush($script:ColGris)), 360, 58)
        }
    })

    $btn.Add_MouseEnter({
        $this.Tag.Hover = $true
        $this.Invalidate()
        Play-HoverSound
    })
    $btn.Add_MouseLeave({ $this.Tag.Hover = $false; $this.Invalidate() })
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
$btn1 = New-GlowButton -Titulo "LIMPIEZA RAPIDA" -Descripcion "Temporales, cache, papelera, RAM (8 tareas)" -Atajo "[1]" -Y 130 -OnClick {
    Start-FregonatorDual -Modo "-AutoRapida"
}
$form.Controls.Add($btn1)

# ============================================================================
# BOTON 2 - LIMPIEZA COMPLETA
# ============================================================================
$btn2 = New-GlowButton -Titulo "LIMPIEZA COMPLETA" -Descripcion "Todo + bloatware, telemetria, optimizacion (13 tareas)" -Atajo "[2]" -Y 225 -OnClick {
    Start-FregonatorDual -Modo "-AutoAvanzada"
}
$form.Controls.Add($btn2)

# ============================================================================
# BOTON 3 - MENU TERMINAL
# ============================================================================
$btn3 = New-GlowButton -Titulo "MENU TERMINAL" -Descripcion "Modo avanzado con todas las opciones" -Atajo "[3]" -Y 320 -OnClick {
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
# BOTON SALIR
# ============================================================================
$btnSalir = New-Object System.Windows.Forms.Button
$btnSalir.FlatStyle = "Flat"
$btnSalir.FlatAppearance.BorderSize = 1
$btnSalir.FlatAppearance.BorderColor = $script:ColGris
$btnSalir.FlatAppearance.MouseOverBackColor = $script:ColRojo
$btnSalir.BackColor = $script:ColBoton
$btnSalir.Location = New-Object System.Drawing.Point(40, 420)
$btnSalir.Size = New-Object System.Drawing.Size(420, 50)
$btnSalir.Cursor = "Hand"
$btnSalir.Tag = @{Hover = $false}

$btnSalir.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $fSalir = New-Object System.Drawing.Font($script:citaroFamily, 14)
    $color = if ($sender.Tag.Hover) { [System.Drawing.Color]::White } else { $script:ColGris }
    $g.DrawString("[X] SALIR", $fSalir, (New-Object System.Drawing.SolidBrush($color)), 165, 14)
})

$btnSalir.Add_MouseEnter({
    $this.Tag.Hover = $true
    $this.Invalidate()
    Play-HoverSound
})
$btnSalir.Add_MouseLeave({ $this.Tag.Hover = $false; $this.Invalidate() })
$btnSalir.Add_Click({ $form.Close() })
$form.Controls.Add($btnSalir)

# ============================================================================
# FOOTER
# ============================================================================
$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text = "v3.5.2"
$lblVersion.Font = New-Object System.Drawing.Font("Consolas", 8)
$lblVersion.ForeColor = [System.Drawing.Color]::FromArgb(50, 50, 55)
$lblVersion.Location = New-Object System.Drawing.Point(40, 485)
$lblVersion.AutoSize = $true
$form.Controls.Add($lblVersion)

$lblFooter = New-Object System.Windows.Forms.Label
$lblFooter.Text = "fregonator.com"
$lblFooter.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblFooter.ForeColor = [System.Drawing.Color]::FromArgb(50, 50, 55)
$lblFooter.Location = New-Object System.Drawing.Point(210, 485)
$lblFooter.AutoSize = $true
$lblFooter.Cursor = "Hand"
$lblFooter.Add_Click({ Start-Process "https://fregonator.com" })
$lblFooter.Add_MouseEnter({ $this.ForeColor = $script:ColCyan })
$lblFooter.Add_MouseLeave({ $this.ForeColor = [System.Drawing.Color]::FromArgb(50, 50, 55) })
$form.Controls.Add($lblFooter)

$lblCredits = New-Object System.Windows.Forms.Label
$lblCredits.Text = "Claude Code"
$lblCredits.Font = New-Object System.Drawing.Font("Segoe UI", 7)
$lblCredits.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
$lblCredits.Location = New-Object System.Drawing.Point(410, 487)
$lblCredits.AutoSize = $true
$form.Controls.Add($lblCredits)

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
    if ($script:SoundPlayer) {
        try { $script:SoundPlayer.Play() } catch {}
    }
})

# ============================================================================
# MOSTRAR
# ============================================================================
[void]$form.ShowDialog()
