# FREGONATOR v3.5.2

## Optimizador de PC para Windows

FREGONATOR es un optimizador de PC gratuito, seguro y transparente. Limpia archivos temporales, libera RAM, actualiza drivers y elimina bloatware.

---

## Caracteristicas

| Aspecto | FREGONATOR | CCleaner |
|---------|------------|----------|
| Precio | Gratis | 30 EUR/ano |
| Tamano | ~160 KB | ~50 MB |
| Telemetria | Ninguna | Si (Avast) |
| Codigo | PowerShell visible | Cerrado |
| Ejecucion | Paralela (8-13 tareas) | Secuencial |

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

### [1] LIMPIEZA RAPIDA (8 tareas, ~30 seg)
- Liberar RAM
- Limpiar archivos temporales
- Vaciar papelera
- Limpiar cache DNS
- Optimizar discos (TRIM SSD)
- Plan energia alto rendimiento
- Actualizar apps (winget)
- Verificar Windows Update

### [2] LIMPIEZA COMPLETA (13 tareas)
Todo lo anterior MAS:
- Eliminar bloatware (CandyCrush, Solitaire, Bing, Xbox)
- Desactivar telemetria
- Limpiar registro MRU
- Matar procesos innecesarios
- Optimizar efectos visuales

### [3] MENU TERMINAL
Opciones adicionales:
- [D] Driver Updater - Actualizar drivers via Windows Update
- [A] Desinstalar apps
- [S] Apps de arranque
- [R] Monitor de rendimiento
- [P] Programar limpieza automatica
- [H] Historial de limpiezas
- [L] Ver logs
- DISM + SFC (reparar Windows)
- Limpieza profunda (5-50 GB)

---

## Instalacion

### Opcion 1: Portable (recomendado)
```
Descomprimir y ejecutar FREGONATOR.bat
```

### Opcion 2: Instalar en Program Files
```
Doble clic en INSTALAR.bat
```

El instalador:
- Copia a `C:\Program Files\FREGONATOR\`
- Crea acceso directo en Escritorio
- Crea entrada en Menu Inicio
- Registra en "Agregar o quitar programas"

---

## Archivos

| Archivo | Descripcion |
|---------|-------------|
| FREGONATOR.bat | Punto de entrada (doble clic) |
| Fregonator.ps1 | Motor principal (~3700 lineas) |
| Fregonator-Launcher.ps1 | GUI menu con sonidos |
| Fregonator-Monitor.ps1 | GUI progreso tiempo real |
| FREGONATOR-Installer.ps1 | Instalador nativo |
| _SONIDOS/bark.wav | Ladrido de Nala |

---

## Requisitos

- Windows 10 / 11
- PowerShell 5.1+ (incluido por defecto)

---

## Seguridad

- **Codigo abierto**: Todo en PowerShell visible
- **Sin telemetria**: No envia datos a ningun servidor
- **Sin navegadores**: No toca contrasenas ni sesiones
- **Bloatware seguro**: No elimina Spotify, Netflix, etc.

---

## Creditos

Desarrollado con Claude Code (Anthropic)
Costa da Morte - www.costa-da-morte.com

2026 - Software libre y gratuito
