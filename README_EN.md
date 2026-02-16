# FREGONATOR v6.0

## PC Optimizer for Windows

FREGONATOR is a free, safe, and transparent PC optimizer. Cleans temp files, frees RAM, updates drivers, and removes bloatware.

**Download:** https://fregonator.com

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

**247K+ views on Reddit r/pcmasterrace** - the community already decided.

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
