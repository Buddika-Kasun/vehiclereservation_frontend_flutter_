@echo off
echo ============================================
echo     FLUTTER DEBUG BUILD SCRIPT
echo ============================================
echo.
echo This script will:
echo 1. Clean all caches
echo 2. Kill running processes
echo 3. Get dependencies
echo 4. Build debug APK
echo.
echo Please close Android Studio/VS Code before continuing!
echo.
pause

echo.
echo Starting PowerShell script...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0build_debug.ps1"

echo.
echo Script execution completed!
pause