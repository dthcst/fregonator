[![GitHub Stars](https://img.shields.io/github/stars/dthcst/fregonator?style=flat-square&color=00E8FF)](https://github.com/dthcst/fregonator/stargazers)
[![License](https://img.shields.io/github/license/dthcst/fregonator?style=flat-square&color=FFB400)](https://github.com/dthcst/fregonator/blob/main/LICENSE)
[![GitHub Downloads](https://img.shields.io/github/downloads/dthcst/fregonator/total?style=flat-square&color=FF1AE5)](https://github.com/dthcst/fregonator/releases)
[![winget](https://img.shields.io/badge/winget-DTHCST.Fregonator-00E8FF?style=flat-square)](https://github.com/microsoft/winget-pkgs/tree/master/manifests/d/DTHCST/Fregonator)
[![Softonic](https://img.shields.io/badge/Softonic-17%2B%20TLDs-FF1AE5?style=flat-square)](https://fregonator.softonic.com/descargar)
[![AlternativeTo](https://img.shields.io/badge/AlternativeTo-CCleaner%20alternative-FFB400?style=flat-square)](https://alternativeto.net/software/fregonator/)
[![Reddit](https://img.shields.io/badge/Reddit-250K%2B%20views-FF4500?style=flat-square)](https://www.reddit.com/r/pcmasterrace/)
[![Web](https://img.shields.io/badge/web-fregonator.com-00E8FF?style=flat-square)](https://fregonator.com)

# FREGONATOR v6.0

## PC Optimizer for Windows | Free CCleaner alternative

FREGONATOR is a free, safe, and transparent PC optimizer. Cleans temp files, frees RAM, updates drivers, and removes bloatware. Open source, zero telemetry, no Pro.

**Download:** https://fregonator.com · **CCleaner comparison:** https://fregonator.com/vs-ccleaner

---

## Independent recognition

> **Google AI Overview (2026):** *"A modern, lightweight open-source alternative built entirely in PowerShell. It has zero network calls or telemetry, runs cleanup tasks in parallel, and does not modify the Windows registry, making it a safer option for system maintenance."*

Ranked **#2 CCleaner alternative** alongside BleachBit and Czkawka in Google AI Overview EN.

**Real metrics (May 2026):** 250K+ Reddit r/pcmasterrace views · ~2,000 downloads · 0 open issues · 0 known bugs · 100% open source auditable PowerShell.

---

## Official distribution · 6 channels

| Channel | Status | Command / URL |
|---------|--------|---------------|
| **GitHub Releases** | LIVE | [github.com/dthcst/fregonator/releases](https://github.com/dthcst/fregonator/releases) |
| **Winget (Microsoft)** | LIVE | `winget install DTHCST.Fregonator` |
| **Softonic** | LIVE · 17+ TLDs | [fregonator.softonic.com](https://fregonator.softonic.com/descargar) |
| **AlternativeTo** | LIVE | [alternativeto.net/software/fregonator](https://alternativeto.net/software/fregonator/) |
| **Chocolatey** | under review | `choco install fregonator` |
| **Reddit r/pcmasterrace** | viral 250K+ | [r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/) |

---

## Why FREGONATOR?

CCleaner was good. In 2017 it got hacked (supply chain attack, 2.27M users affected). Avast bought it. Now it has telemetry, upsell popups, and the free version barely does anything.

Fregonator does the same job, better, free, in 220 KB.

| Aspect | FREGONATOR | CCleaner |
|--------|------------|----------|
| Price | Free, forever | Freemium ($30/year Pro) |
| Installer size | 2.2 MB | ~50 MB |
| Portable | 220 KB | None |
| Telemetry | None. Zero. Nothing | Yes (Avast/Gen Digital) |
| Source code | Open PowerShell, auditable | Closed |
| Execution | Parallel (8-13 tasks at once) | Sequential |
| Browser safety | Never touches passwords or sessions | Clears cookies and sessions |
| Security track record | Clean | Hacked 2017, v7 broke PCs |
| Admin required | No | Yes (some features) |
| Updates | winget, free | Pro only |
| Bloatware removal | Safe (keeps Spotify, Netflix) | Aggressive |

**250K+ views on Reddit r/pcmasterrace** - the community already decided.

---

## Installation

### Option 1: One-liner (recommended)
```powershell
irm fregonator.com/install.ps1 | iex
```
Downloads, installs to %LOCALAPPDATA%, creates desktop shortcut. No admin required.

### Option 2: Installer
```
Download FREGONATOR-6.0-Setup.exe and run
```
- Professional install wizard
- Multi-language (English/Spanish)
- Desktop shortcut
- Start Menu entry
- Uninstaller included

### Option 3: Portable (no install)
```
Extract FREGONATOR-6.0-Setup.zip
Run FREGONATOR.bat
```

---

## Usage

### GUI (Recommended)
```
Double-click FREGONATOR.bat
```

### From Terminal
```powershell
# Interactive mode
.\Fregonator.ps1

# Silent mode (scripts/scheduled tasks)
.\Fregonator.ps1 -Silent

# Advanced cleanup silent
.\Fregonator.ps1 -Avanzada
```

---

## Features

### [1] QUICK CLEANUP (8 tasks, ~30 sec)
- Free RAM
- Clean temp files
- Empty recycle bin
- Flush DNS cache
- Optimize disks (TRIM SSD)
- High performance power plan
- Update apps (winget)
- Check Windows Update

### [2] FULL CLEANUP (13 tasks)
Everything above PLUS:
- Remove bloatware (CandyCrush, Solitaire, Bing, Xbox)
- Disable telemetry
- Clean MRU registry
- Kill unnecessary processes
- Optimize visual effects

### [3] TERMINAL MODE
Additional options:
- [D] Driver Updater - Update drivers via Windows Update
- [A] Uninstall apps
- [S] Startup apps
- [R] Performance monitor
- [P] Schedule automatic cleanup
- [H] Cleanup history
- [L] View logs
- DISM + SFC (repair Windows)
- Deep cleanup (5-50 GB)

---

## Requirements

- Windows 10 / 11
- PowerShell 5.1+ (included by default)

---

## Security

- **Open source**: All code visible in PowerShell
- **No telemetry**: Sends no data anywhere
- **No browser access**: Doesn't touch passwords or sessions
- **Safe bloatware removal**: Doesn't remove Spotify, Netflix, etc.

---

## Language

The app auto-detects your system language (English/Spanish).
To manually switch: press **[I]** in the terminal menu.

---

## Credits

Developed with Claude Code (Anthropic)
Costa da Morte - www.costa-da-morte.com

2026 - Free and open source software
