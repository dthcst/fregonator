# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 6.0.x   | :white_check_mark: |
| < 6.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in FREGONATOR, please report it via:

1. **GitHub Issues**: [Open an issue](https://github.com/dthcst/fregonator/issues) with the label `security`
2. **Email**: dev@costa-da-morte.com

### What to include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response time:
- Initial response: 48 hours
- Fix timeline: Depends on severity (critical: 24h, high: 7 days, medium: 30 days)

## Security Features

FREGONATOR is designed with security in mind:

- **100% visible code**: All PowerShell source code is readable
- **No compiled binaries**: Nothing hidden, nothing obfuscated
- **No telemetry**: Zero data collection
- **No network calls**: Except for winget updates (Windows native)
- **No background services**: Runs only when you click it
- **No admin persistence**: Doesn't install services or scheduled tasks by default

## Code Review

You are encouraged to review the code before running:

```powershell
# Main files to review:
# - Fregonator.ps1 (~3800 lines) - Main engine
# - Fregonator-Launcher.ps1 - GUI launcher
# - Fregonator-Monitor.ps1 - Progress monitor
```

## Code Signing Policy

Free code signing provided by [SignPath.io](https://signpath.io), certificate by [SignPath Foundation](https://signpath.org).

**Signing team:**
- Martin Caamano Castineira - Author, Reviewer, Approver

**Privacy:** FREGONATOR does not collect, store, or transfer any user data.

Thank you for helping keep FREGONATOR safe!
