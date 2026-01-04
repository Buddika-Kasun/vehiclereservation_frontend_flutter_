# ============================================
# OPTIMIZED FLUTTER DEBUG BUILD SCRIPT
# ============================================

param(
    [switch]$QuickBuild,
    [switch]$NoPrompt,
    [switch]$BuildOnly,
    [string]$Target = "apk"
)

# ============================================
# FUNCTION DEFINITIONS
# ============================================
function Write-Step {
    param([string]$Message, [int]$Step, [int]$Total, [string]$Color = "Yellow")
    Write-Host "`n[$Step/$Total] $Message" -ForegroundColor $Color
}

function Write-Info {
    param([string]$Message, [string]$Indent = "  ")
    Write-Host "$Indent$Message" -ForegroundColor "Gray"
}

function Write-Success {
    param([string]$Message, [string]$Indent = "  ")
    Write-Host "$Indent$Message" -ForegroundColor "Green"
}

function Write-Warning {
    param([string]$Message, [string]$Indent = "  ")
    Write-Host "$Indent$Message" -ForegroundColor "Yellow"
}

function Get-StorageInfo {
    try {
        $drive = Get-PSDrive C -ErrorAction Stop
        $freeGB = [math]::Round($drive.Free / 1GB, 2)
        $usedGB = [math]::Round($drive.Used / 1GB, 2)
        $totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)
        return @{ Free = $freeGB; Used = $usedGB; Total = $totalGB }
    } catch {
        return @{ Free = 0; Used = 0; Total = 0 }
    }
}

function Clean-GradleCache-Aggressive {
    Write-Info "Performing aggressive Gradle cache cleanup..."
    
    # Clean the ENTIRE .gradle directory (except wrapper)
    $gradleDir = "$env:USERPROFILE\.gradle"
    if (Test-Path $gradleDir) {
        Write-Info "Backing up Gradle wrapper..."
        
        # Backup wrapper if it exists
        $wrapperDir = "$gradleDir\wrapper"
        $hasWrapper = Test-Path $wrapperDir
        $tempBackup = $null
        
        if ($hasWrapper) {
            $tempBackup = "$env:TEMP\gradle-wrapper-backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item -Path $wrapperDir -Destination $tempBackup -Recurse -Force -ErrorAction SilentlyContinue
            Write-Info "Wrapper backed up to: $tempBackup"
        }
        
        # Remove entire .gradle directory
        Write-Info "Removing entire Gradle cache directory..."
        Remove-Item -Path $gradleDir -Recurse -Force -ErrorAction SilentlyContinue
        
        # Recreate directory
        New-Item -ItemType Directory -Path $gradleDir -Force | Out-Null
        
        # Restore wrapper if we backed it up
        if ($hasWrapper -and (Test-Path $tempBackup)) {
            Write-Info "Restoring Gradle wrapper..."
            Copy-Item -Path "$tempBackup\*" -Destination "$gradleDir\wrapper" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $tempBackup -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-Success "Completely cleaned Gradle cache"
    }
    
    # Also clean project Gradle directories
    $projectGradleDirs = @("\.gradle", "android\.gradle")
    foreach ($dir in $projectGradleDirs) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Info "Cleaned project $dir"
        }
    }
}

function Clean-FlutterCache {
    Write-Info "Cleaning Flutter cache..."
    
    # Find Flutter SDK path
    $flutterPath = flutter --version 2>$null | Select-String "Flutter.*SDK"
    if ($flutterPath) {
        $sdkPath = $flutterPath -replace ".*\s+at\s+(.*)", '$1'
    } else {
        $sdkPath = "$env:LOCALAPPDATA\flutter"
    }
    
    # Clean Flutter's bin/cache
    $flutterCache = "$sdkPath\bin\cache"
    if (Test-Path $flutterCache) {
        Remove-Item -Path $flutterCache -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Cleaned Flutter cache"
    }
}

# ============================================
# HEADER
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
if ($QuickBuild) {
    Write-Host "    QUICK DEBUG BUILD                    " -ForegroundColor Cyan
} else {
    Write-Host "    FULL DEBUG BUILD                    " -ForegroundColor Cyan
}
Write-Host "    Target: $Target" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ============================================
# QUICK BUILD PATH
# ============================================
if ($QuickBuild -or $BuildOnly) {
    Write-Step -Message "Quick Debug Build" -Step 1 -Total 3
    
    if (-not $BuildOnly) {
        Write-Info "Cleaning project..."
        flutter clean 2>$null
        flutter pub get
    }
    
    Write-Info "Building debug $Target..."
    $startTime = Get-Date
    
    try {
        if ($Target -eq "apk") {
            flutter build apk --debug --no-track-widget-creation
        } elseif ($Target -eq "aab") {
            flutter build appbundle --debug --no-track-widget-creation
        } else {
            flutter build apk --debug --no-track-widget-creation
        }
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        Write-Success "Build completed in $($duration.TotalSeconds.ToString('0.00')) seconds"
        
        # Show output
        if ($Target -eq "apk") {
            $outputPath = "build\app\outputs\flutter-apk\app-debug.apk"
        } else {
            $outputPath = "build\app\outputs\bundle\debug\app-debug.aab"
        }
        
        if (Test-Path $outputPath) {
            $size = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
            Write-Success "Output: $outputPath ($size MB)"
        }
    } catch {
        Write-Host "  Build failed: $_" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "    Quick Build Complete!                " -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    if (-not $NoPrompt) { pause }
    exit 0
}

# ============================================
# FULL DEBUG BUILD
# ============================================
Write-Step -Message "Stopping build processes" -Step 1 -Total 8

$processes = @("java", "javaw", "gradle", "dart")
foreach ($proc in $processes) {
    $running = Get-Process $proc* -ErrorAction SilentlyContinue | Measure-Object
    if ($running.Count -gt 0) {
        Get-Process $proc* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Info "Stopped $proc ($($running.Count) processes)"
    }
}
Start-Sleep -Seconds 2

# ============================================
Write-Step -Message "Aggressive Gradle cache cleanup" -Step 2 -Total 8

Clean-GradleCache-Aggressive

# ============================================
Write-Step -Message "Flutter cache cleanup" -Step 3 -Total 8

Clean-FlutterCache

# ============================================
Write-Step -Message "Project cleaning" -Step 4 -Total 8

Write-Info "Running flutter clean..."
flutter clean

# Clean all project build directories
$buildDirs = @(
    "build",
    "android\build", 
    "android\app\build",
    ".dart_tool",
    ".flutter-plugins",
    ".flutter-plugins-dependencies"
)

foreach ($dir in $buildDirs) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Info "Cleaned $dir"
    }
}

# ============================================
Write-Step -Message "Getting dependencies" -Step 5 -Total 8

Write-Info "Running flutter pub get..."
flutter pub get

Write-Info "Cleaning Android project..."
Set-Location android
./gradlew clean 2>$null
Set-Location ..

# ============================================
Write-Step -Message "Storage check" -Step 6 -Total 8

$storage = Get-StorageInfo
Write-Info "Disk C: Free $($storage.Free) GB / Used $($storage.Used) GB / Total $($storage.Total) GB"

if ($storage.Free -lt 5) {
    Write-Warning "Low disk space! Only $($storage.Free) GB free."
    Write-Info "Build may fail due to insufficient space."
}

# ============================================
Write-Step -Message "Building Debug $Target" -Step 7 -Total 8

Write-Info "Starting build..."
$startTime = Get-Date

try {
    # Build with --no-daemon to avoid Gradle daemon issues
    if ($Target -eq "apk") {
        flutter build apk --debug --no-track-widget-creation
    } else {
        flutter build appbundle --debug --no-track-widget-creation
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Success "Build completed in $($duration.TotalSeconds.ToString('0.00')) seconds"
} catch {
    Write-Warning "Build failed! Trying manual approach..."
    
    # Manual Gradle build
    Write-Info "Running manual Gradle build..."
    Set-Location android
    try {
        # Clean first
        ./gradlew clean 2>$null
        
        # Build with verbose output
        ./gradlew assembleDebug --no-daemon --console=plain --info
        
        Set-Location ..
        
        # Check for output
        $apkPath = "android\app\build\outputs\apk\debug\app-debug.apk"
        if (Test-Path $apkPath) {
            Write-Success "Manual Gradle build successful!"
        } else {
            Write-Warning "APK not found. Checking for other outputs..."
        }
    } catch {
        Write-Host "  Manual build failed: $_" -ForegroundColor Red
        exit 1
    }
}

# ============================================
Write-Step -Message "Build Information" -Step 8 -Total 8

# Check for output files
$possibleApkPaths = @(
    "build\app\outputs\flutter-apk\app-debug.apk",
    "android\app\build\outputs\apk\debug\app-debug.apk",
    "build\app\outputs\apk\debug\app-debug.apk"
)

$found = $false
foreach ($apkPath in $possibleApkPaths) {
    if (Test-Path $apkPath) {
        $size = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
        Write-Success "Debug APK: $apkPath"
        Write-Info "Size: $($size.ToString('0.00')) MB"
        $found = $true
        break
    }
}

if (-not $found) {
    Write-Host "  No output file found!" -ForegroundColor Red
    
    # Check if build directory exists at all
    if (Test-Path "build") {
        Write-Info "Checking build directory contents..."
        $buildContents = Get-ChildItem -Path "build" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 10
        if ($buildContents) {
            Write-Info "Found in build directory:"
            foreach ($item in $buildContents) {
                Write-Info "  $($item.FullName)"
            }
        }
    }
}

# Final storage check
$finalStorage = Get-StorageInfo
$storageUsed = [math]::Round(($storage.Free - $finalStorage.Free), 2)
if ($storageUsed -gt 0) {
    Write-Info "Storage used by build: $storageUsed GB"
}

# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "    Debug Build Complete!                  " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if (-not $NoPrompt) { pause }