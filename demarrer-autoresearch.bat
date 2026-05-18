@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0demarrer-autoresearch.ps1"
if errorlevel 1 (
  echo.
  echo Une erreur est survenue.
  pause
)
