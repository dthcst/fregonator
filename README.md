# FREGONATOR v6.0

## Optimizador de PC para Windows

FREGONATOR es un optimizador de PC gratuito, seguro y transparente. Limpia archivos temporales, libera RAM, actualiza drivers y elimina bloatware.

**247K+ views en Reddit** | **~2,000 descargas**

**Descarga:** https://fregonator.com

---

## Por que Fregonator?

CCleaner fue bueno. En 2017 lo hackearon (supply chain attack, 2.27M usuarios afectados). Avast lo compro. Ahora tiene telemetria, popups de upsell y la version gratuita apenas hace nada.

Fregonator hace lo mismo, mejor, gratis y en 220 KB.

| Aspecto | FREGONATOR | CCleaner |
|---------|------------|----------|
| Precio | Gratis, para siempre | Freemium (30 EUR/ano Pro) |
| Tamano instalador | 2.2 MB | ~50 MB |
| Portable | 220 KB | No existe |
| Telemetria | Ninguna. Zero. Nada | Si (Avast/Gen Digital) |
| Codigo fuente | PowerShell visible, auditable | Cerrado |
| Ejecucion | Paralela (8-13 tareas a la vez) | Secuencial |
| Navegadores | No toca passwords ni sesiones | Borra cookies y sesiones |
| Historial seguridad | Limpio | Hackeado 2017, v7 rompio PCs |
| Requiere admin | No | Si (algunas funciones) |
| Actualizaciones | winget gratis | Solo version Pro |
| Bloatware | Seguro (preserva Spotify, Netflix) | Agresivo |

**247K+ views en Reddit r/pcmasterrace** - la comunidad ya decidio.

---

## Instalación

### Opción 1: One-liner (recomendado)
```powershell
irm fregonator.com/install.ps1 | iex
```
Descarga, instala en %LOCALAPPDATA%, crea acceso directo. Sin admin.

### Opción 2: Instalador
```
Descargar FREGONATOR-6.0-Setup.exe y ejecutar
```
- Wizard de instalación profesional
- Multi-idioma (Español/English)
- Acceso directo en Escritorio
- Entrada en Menú Inicio
- Desinstalador incluido

### Opción 3: Portable (sin instalar)
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
- **Sin navegadores**: No toca contraseñas ni sesiones
- **Bloatware seguro**: No elimina Spotify, Netflix, etc.

---

## Idioma

La app detecta automaticamente el idioma del sistema (Español/English).
Para cambiar manualmente: pulsa **[I]** en el menu terminal.

---

## Créditos

Desarrollado con Claude Code (Anthropic)
Costa da Morte - www.costa-da-morte.com

2026 - Software libre y gratuito
