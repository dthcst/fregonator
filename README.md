[![GitHub Stars](https://img.shields.io/github/stars/dthcst/fregonator?style=flat-square&color=00E8FF)](https://github.com/dthcst/fregonator/stargazers)
[![License](https://img.shields.io/github/license/dthcst/fregonator?style=flat-square&color=FFB400)](https://github.com/dthcst/fregonator/blob/main/LICENSE)
[![GitHub Downloads](https://img.shields.io/github/downloads/dthcst/fregonator/total?style=flat-square&color=FF1AE5)](https://github.com/dthcst/fregonator/releases)
[![winget](https://img.shields.io/badge/winget-DTHCST.Fregonator-00E8FF?style=flat-square)](https://github.com/microsoft/winget-pkgs/tree/master/manifests/d/DTHCST/Fregonator)
[![Softonic](https://img.shields.io/badge/Softonic-17%2B%20TLDs-FF1AE5?style=flat-square)](https://fregonator.softonic.com/descargar)
[![AlternativeTo](https://img.shields.io/badge/AlternativeTo-CCleaner%20alternative-FFB400?style=flat-square)](https://alternativeto.net/software/fregonator/)
[![Reddit](https://img.shields.io/badge/Reddit-250K%2B%20views-FF4500?style=flat-square)](https://www.reddit.com/r/pcmasterrace/)
[![Web](https://img.shields.io/badge/web-fregonator.com-00E8FF?style=flat-square)](https://fregonator.com)

# FREGONATOR v6.0

## Optimizador de PC para Windows | Alternativa libre a CCleaner

FREGONATOR es un optimizador de PC gratuito, seguro y transparente. Limpia archivos temporales, libera RAM, actualiza drivers y elimina bloatware. Open source, sin telemetría, sin Pro.

**Descarga:** https://fregonator.com · **Comparativa CCleaner:** https://fregonator.com/vs-ccleaner

---

## Reconocimiento independiente

> **Google AI Overview (2026):** *"A modern, lightweight open-source alternative built entirely in PowerShell. It has zero network calls or telemetry, runs cleanup tasks in parallel, and does not modify the Windows registry, making it a safer option for system maintenance."*

Posicionado **#2 alternativa CCleaner** junto a BleachBit y Czkawka en Google AI Overview EN.

**Métricas reales (mayo 2026):** 250K+ views Reddit r/pcmasterrace · ~2.000 descargas · 0 issues abiertos · 0 bugs conocidos · 100% open source PowerShell auditable.

---

## Distribución oficial · 6 canales

| Canal | Estado | Comando / URL |
|-------|--------|---------------|
| **GitHub Releases** | LIVE | [github.com/dthcst/fregonator/releases](https://github.com/dthcst/fregonator/releases) |
| **Winget (Microsoft)** | LIVE | `winget install DTHCST.Fregonator` |
| **Softonic** | LIVE · 17+ TLDs | [fregonator.softonic.com/descargar](https://fregonator.softonic.com/descargar) |
| **AlternativeTo** | LIVE | [alternativeto.net/software/fregonator](https://alternativeto.net/software/fregonator/) |
| **Chocolatey** | en revisión | `choco install fregonator` |
| **Reddit r/pcmasterrace** | viral 250K+ | [r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/) |

---

## Por qué Fregonator?

CCleaner fue bueno. En 2017 lo hackearon (supply chain attack, 2.27M usuarios afectados). Avast lo compró. Ahora tiene telemetría, popups de upsell y la versión gratuita apenas hace nada.

Fregonator hace lo mismo, mejor, gratis y en 220 KB.

| Aspecto | FREGONATOR | CCleaner |
|---------|------------|----------|
| Precio | Gratis, para siempre | Freemium (30 EUR/año Pro) |
| Tamaño instalador | 2.2 MB | ~50 MB |
| Portable | 220 KB | No existe |
| Telemetría | Ninguna. Zero. Nada | Sí (Avast/Gen Digital) |
| Código fuente | PowerShell visible, auditable | Cerrado |
| Ejecución | Paralela (8-13 tareas a la vez) | Secuencial |
| Navegadores | No toca contraseñas ni sesiones | Borra cookies y sesiones |
| Historial seguridad | Limpio | Hackeado 2017, v7 rompió PCs |
| Requiere admin | No | Sí (algunas funciones) |
| Actualizaciones | winget gratis | Solo versión Pro |
| Bloatware | Seguro (preserva Spotify, Netflix) | Agresivo |

**250K+ views en Reddit r/pcmasterrace** - la comunidad ya decidió.

---

## Instalación

### Opción 1: One-liner (recomendado)
```powershell
irm fregonator.com/install.ps1 | iex
```
Descarga, instala en %LOCALAPPDATA%, crea acceso directo. Sin admin.

### Opción 2: winget (Windows Package Manager)
```powershell
winget install DTHCST.Fregonator
```
Instalación oficial desde el repositorio de Microsoft.

### Opción 3: Instalador
```
Descargar FREGONATOR-6.0-Setup.exe y ejecutar
```
- Wizard de instalación profesional
- Multi-idioma (Español/English/Galego)
- Acceso directo en Escritorio
- Entrada en Menú Inicio
- Desinstalador incluido

### Opción 4: Portable (sin instalar)
```
Descomprimir FREGONATOR-6.0-Setup.zip
Ejecutar FREGONATOR.bat
```

---

## Modos de Uso

### GUI (Recomendado)
```
Doble clic en FREGONATOR.bat
```

### Desde Terminal
```powershell
# Interactivo
.\Fregonator.ps1

# Modo silencioso (scripts/tareas)
.\Fregonator.ps1 -Silent

# Limpieza avanzada silenciosa
.\Fregonator.ps1 -Avanzada
```

---

## Funciones

### [1] LIMPIEZA RÁPIDA (8 tareas, ~30 seg)
- Liberar RAM
- Limpiar archivos temporales
- Vaciar papelera
- Limpiar caché DNS
- Optimizar discos (TRIM SSD)
- Plan energía alto rendimiento
- Actualizar apps (winget)
- Verificar Windows Update

### [2] LIMPIEZA COMPLETA (13 tareas)
Todo lo anterior MÁS:
- Eliminar bloatware (CandyCrush, Solitaire, Bing, Xbox)
- Desactivar telemetría
- Limpiar registro MRU
- Matar procesos innecesarios
- Optimizar efectos visuales

### [3] TERMINAL MS-DOS
Opciones adicionales:
- [D] Driver Updater - Actualizar drivers vía Windows Update
- [A] Desinstalar apps
- [S] Apps de arranque
- [R] Monitor de rendimiento
- [P] Programar limpieza automática
- [H] Historial de limpiezas
- [L] Ver logs
- DISM + SFC (reparar Windows)
- Limpieza profunda (5-50 GB)

---

## Requisitos

- Windows 10 / 11
- PowerShell 5.1+ (incluido por defecto)

---

## Seguridad

- **Código abierto**: Todo en PowerShell visible
- **Sin telemetría**: No envía datos a ningún servidor
- **Sin navegadores**: No toca contraseñas ni sesiones activas
- **Bloatware seguro**: Preserva Spotify, Netflix, etc.

---

## Idioma

La app detecta automáticamente el idioma del sistema (Español/English/Galego).
Para cambiar manualmente: pulsa **[I]** en el menú terminal o en el selector de idioma de la GUI.

---

## Créditos

Desarrollado con Claude Code (Anthropic)
Costa da Morte - www.costa-da-morte.com

2026 - Software libre y gratuito
