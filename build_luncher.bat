@echo off
setlocal enabledelayedexpansion

:: ============================================
::     FLUTTER BUILD SCRIPT LAUNCHER
:: ============================================
:MAIN_MENU
cls
echo ============================================
echo     FLUTTER BUILD SCRIPT LAUNCHER
echo ============================================
echo.
echo Please select build type:
echo.
echo   [1] Debug Build (Development)
echo   [2] Release Build (Production)
echo   [3] Clean Utilities
echo   [4] Quick Commands
echo   [5] Fix Common Issues
echo   [6] Exit
echo.
echo ============================================

set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto DEBUG_BUILD
if "%choice%"=="2" goto RELEASE_BUILD
if "%choice%"=="3" goto CLEAN_UTILITIES
if "%choice%"=="4" goto QUICK_COMMANDS
if "%choice%"=="5" goto FIX_ISSUES
if "%choice%"=="6" goto EXIT
goto MAIN_MENU

:: ============================================
:: DEBUG BUILD
:: ============================================
:DEBUG_BUILD
cls
echo ============================================
echo     DEBUG BUILD OPTIONS
echo ============================================
echo.
echo Select debug build type:
echo.
echo   [1] Quick Debug (Fast, minimal cleaning)
echo   [2] Full Debug (Clean all, build APK)
echo   [3] Debug App Bundle (AAB)
echo   [4] Build Only (No cleaning)
echo   [5] Back to Main Menu
echo.
set /p debug_choice="Select option (1-5): "

if "%debug_choice%"=="1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0build_debug.ps1" -QuickBuild -Target apk
    goto PAUSE_RETURN
)

if "%debug_choice%"=="2" (
    cls
    echo ============================================
    echo     FULL DEBUG BUILD
    echo ============================================
    echo.
    echo This will:
    echo   1. Stop running processes
    echo   2. Clean project caches
    echo   3. Get dependencies
    echo   4. Build debug APK
    echo.
    set /p confirm="Start full debug build? (Y/n): "
    
    if /i not "%confirm%"=="n" (
        powershell -ExecutionPolicy Bypass -File "%~dp0build_debug.ps1"
        goto PAUSE_RETURN
    )
    goto DEBUG_BUILD
)

if "%debug_choice%"=="3" (
    powershell -ExecutionPolicy Bypass -File "%~dp0build_debug.ps1" -Target aab
    goto PAUSE_RETURN
)

if "%debug_choice%"=="4" (
    powershell -ExecutionPolicy Bypass -File "%~dp0build_debug.ps1" -BuildOnly -Target apk
    goto PAUSE_RETURN
)

if "%debug_choice%"=="5" goto MAIN_MENU
goto DEBUG_BUILD

:: ============================================
:: RELEASE BUILD
:: ============================================
:RELEASE_BUILD
cls
echo ============================================
echo     RELEASE BUILD OPTIONS
echo ============================================
echo.
echo Select release build type:
echo.
echo   [1] Quick Release (No signing, fast)
echo   [2] Full Release with Signing
echo   [3] Full Release without Signing
echo   [4] Build APK only (no signing)
echo   [5] Build App Bundle (AAB) only (no signing)
echo   [6] Back to Main Menu
echo.
set /p release_choice="Select option (1-6): "

if "%release_choice%"=="1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0build_release.ps1" -QuickBuild -NoSigning
    goto PAUSE_RETURN
)

if "%release_choice%"=="2" (
    cls
    echo ============================================
    echo     FULL RELEASE WITH SIGNING
    echo ============================================
    echo.
    echo This will:
    echo   1. Configure signing (keystore required)
    echo   2. Clean project and fix dependencies
    echo   3. Build signed release APK/AAB
    echo.
    echo NOTE: You need a keystore file!
    echo.
    set /p confirm="Continue? (Y/n): "
    
    if /i not "%confirm%"=="n" (
        powershell -ExecutionPolicy Bypass -File "%~dp0build_release.ps1"
        goto PAUSE_RETURN
    )
    goto RELEASE_BUILD
)

if "%release_choice%"=="3" (
    cls
    echo ============================================
    echo     FULL RELEASE WITHOUT SIGNING
    echo ============================================
    echo.
    echo This will:
    echo   1. Clean project and fix dependencies
    echo   2. Build unsigned release APK/AAB
    echo   3. Output will be in build folder
    echo.
    set /p confirm="Continue? (Y/n): "
    
    if /i not "%confirm%"=="n" (
        powershell -ExecutionPolicy Bypass -File "%~dp0build_release.ps1" -NoSigning
        goto PAUSE_RETURN
    )
    goto RELEASE_BUILD
)

if "%release_choice%"=="4" (
    powershell -ExecutionPolicy Bypass -File "%~dp0build_release.ps1" -TargetPlatforms apk -NoSigning -QuickBuild
    goto PAUSE_RETURN
)

if "%release_choice%"=="5" (
    powershell -ExecutionPolicy Bypass -File "%~dp0build_release.ps1" -TargetPlatforms aab -NoSigning -QuickBuild
    goto PAUSE_RETURN
)

if "%release_choice%"=="6" goto MAIN_MENU
goto RELEASE_BUILD

:: ============================================
:: CLEAN UTILITIES
:: ============================================
:CLEAN_UTILITIES
cls
echo ============================================
echo     CLEANING UTILITIES
echo ============================================
echo.
echo Select cleaning option:
echo.
echo   [1] Project Clean Only (Safe)
echo   [2] Flutter Cache Clean
echo   [3] Gradle Cache Clean
echo   [4] Full System Clean (WARNING!)
echo   [5] Fix Duplicate Dependencies
echo   [6] Back to Main Menu
echo.
set /p clean_choice="Select option (1-6): "

if "%clean_choice%"=="1" (
    powershell -ExecutionPolicy Bypass -file "%~dp0build_clean.ps1" -CleanProjectOnly
    goto PAUSE_RETURN
)

if "%clean_choice%"=="2" (
    powershell -ExecutionPolicy Bypass -file "%~dp0build_clean.ps1" -CleanFlutterOnly
    goto PAUSE_RETURN
)

if "%clean_choice%"=="3" (
    powershell -ExecutionPolicy Bypass -file "%~dp0build_clean.ps1" -CleanGradleOnly
    goto PAUSE_RETURN
)

if "%clean_choice%"=="4" (
    cls
    echo ============================================
    echo     FULL SYSTEM CLEAN - WARNING!
    echo ============================================
    echo.
    echo THIS WILL:
    echo   • Delete ALL Gradle caches
    echo   • Delete ALL Flutter caches
    echo   • Delete ALL Android build files
    echo.
    echo WARNING: Next build will be VERY SLOW!
    echo          Everything needs to re-download!
    echo.
    set /p confirm="Are you ABSOLUTELY sure? (type YES to continue): "
    
    if /i "%confirm%"=="YES" (
        echo.
        echo Starting Full System Clean...
        echo.
        powershell -ExecutionPolicy Bypass -file "%~dp0build_clean.ps1" -FullClean
        goto PAUSE_RETURN
    )
    echo.
    echo Clean cancelled.
    pause
    goto CLEAN_UTILITIES
)

if "%clean_choice%"=="5" (
    powershell -ExecutionPolicy Bypass -file "%~dp0build_fix.ps1" -FixDependencies
    goto PAUSE_RETURN
)

if "%clean_choice%"=="6" goto MAIN_MENU
goto CLEAN_UTILITIES

:: ============================================
:: QUICK COMMANDS
:: ============================================
:QUICK_COMMANDS
cls
echo ============================================
echo     QUICK COMMANDS
echo ============================================
echo.
echo Select quick command:
echo.
echo   [1] Flutter Clean
echo   [2] Flutter Pub Get
echo   [3] Flutter Doctor
echo   [4] Build APK (direct)
echo   [5] Build App Bundle (AAB) (direct)
echo   [6] Back to Main Menu
echo.
set /p quick_choice="Select option (1-6): "

if "%quick_choice%"=="1" (
    echo.
    echo Running: flutter clean
    echo.
    flutter clean
    goto PAUSE_RETURN
)

if "%quick_choice%"=="2" (
    echo.
    echo Running: flutter pub get
    echo.
    flutter pub get
    goto PAUSE_RETURN
)

if "%quick_choice%"=="3" (
    echo.
    echo Running: flutter doctor -v
    echo.
    flutter doctor -v
    goto PAUSE_RETURN
)

if "%quick_choice%"=="4" (
    echo.
    echo Building APK directly...
    echo.
    flutter build apk --debug
    goto PAUSE_RETURN
)

if "%quick_choice%"=="5" (
    echo.
    echo Building App Bundle (AAB) directly...
    echo.
    flutter build appbundle --debug
    goto PAUSE_RETURN
)

if "%quick_choice%"=="6" goto MAIN_MENU
goto QUICK_COMMANDS

:: ============================================
:: FIX ISSUES
:: ============================================
:FIX_ISSUES
cls
echo ============================================
echo     FIX COMMON ISSUES
echo ============================================
echo.
echo Select issue to fix:
echo.
echo   [1] Fix Duplicate Class Error
echo   [2] Fix Missing Keystore
echo   [3] Fix Gradle Sync Errors
echo   [4] Update Flutter Dependencies
echo   [5] Check Build Configuration
echo   [6] Back to Main Menu
echo.
set /p fix_choice="Select option (1-6): "

if "%fix_choice%"=="1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0build_fix.ps1" -FixDependencies
    goto PAUSE_RETURN
)

if "%fix_choice%"=="2" (
    powershell -ExecutionPolicy Bypass -file "%~dp0build_fix.ps1" -CheckKeystore
    goto PAUSE_RETURN
)

if "%fix_choice%"=="3" (
    powershell -ExecutionPolicy Bypass -file "%~dp0build_fix.ps1" -FixGradle
    goto PAUSE_RETURN
)

if "%fix_choice%"=="4" (
    powershell -ExecutionPolicy Bypass -file "%~dp0build_fix.ps1" -UpdateDependencies
    goto PAUSE_RETURN
)

if "%fix_choice%"=="5" (
    powershell -ExecutionPolicy Bypass -file "%~dp0build_fix.ps1" -CheckConfig
    goto PAUSE_RETURN
)

if "%fix_choice%"=="6" goto MAIN_MENU
goto FIX_ISSUES

:: ============================================
:: PAUSE AND RETURN
:: ============================================
:PAUSE_RETURN
echo.
echo ============================================
echo     OPERATION COMPLETED
echo ============================================
echo.
set /p return="Return to main menu? (Y/n): "
if /i "%return%"=="n" (
    goto EXIT
)
goto MAIN_MENU

:: ============================================
:: EXIT
:: ============================================
:EXIT
echo.
echo Thank you for using Flutter Build Scripts!
echo.
pause
exit /b 0