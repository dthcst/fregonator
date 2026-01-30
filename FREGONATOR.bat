@echo off
cd /d "%~dp0"
title FREGONATOR

:: Limpiar archivos de sesion anterior
if exist "%PUBLIC%\fregonator_progress.json" del "%PUBLIC%\fregonator_progress.json" >nul 2>&1
if exist "%PUBLIC%\fregonator_abort.flag" del "%PUBLIC%\fregonator_abort.flag" >nul 2>&1

:: Mostrar launcher GUI
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "Fregonator-Launcher.ps1"
