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
# FULL DEBUG BUILD (YOUR ORIGINAL SCRIPT)
# ============================================
Write-Step -Message "Stopping build processes" -Step 1 -Total 7

$processes = @("java", "javaw", "gradle", "dart")
foreach ($proc in $processes) {
    $running = Get-Process $proc* -ErrorAction SilentlyContinue | Measure-Object
    if ($running.Count -gt 0) {
        Get-Process $proc* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Info "Stopped $proc ($($running.Count) processes)"
    }
}
Start-Sleep -Seconds 1

# ============================================
Write-Step -Message "Selective cleaning" -Step 2 -Total 7

Write-Info "Running flutter clean (project only)..."
flutter clean

$projectBuildDirs = @("build", ".gradle")
foreach ($dir in $projectBuildDirs) {
    $path = "android/$dir"
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Cleaned project $dir"
    }
}

# ============================================
Write-Step -Message "Checking Gradle cache" -Step 3 -Total 7

$transformsPath = "$env:USERPROFILE\.gradle\caches\transforms-*"
if (Test-Path $transformsPath) {
    $transformsSize = [math]::Round((Get-ChildItem $transformsPath -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB, 2)
    Write-Info "Found transforms cache: ~$transformsSize MB"
    
    if (-not $NoPrompt) {
        $cleanTransforms = Read-Host "  Clean transforms metadata? (y/N)"
        if ($cleanTransforms -eq 'y') {
            Remove-Item -Path $transformsPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Success "Cleaned transforms metadata"
        }
    }
}

# ============================================
Write-Step -Message "Getting dependencies" -Step 4 -Total 7

Write-Info "Running flutter pub get (offline first)..."
flutter pub get --offline 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Offline failed, trying online..."
    flutter pub get
}

Write-Info "Cleaning Android project..."
Set-Location android
./gradlew clean 2>$null
Set-Location ..

# ============================================
Write-Step -Message "Storage check" -Step 5 -Total 7

$storage = Get-StorageInfo
Write-Info "Disk C: Free $($storage.Free) GB / Used $($storage.Used) GB / Total $($storage.Total) GB"

if ($storage.Free -lt 2) {
    Write-Warning "Less than 2GB free space!"
    if (-not $NoPrompt) {
        $continue = Read-Host "  Continue anyway? (y/N)"
        if ($continue -ne 'y') {
            Write-Host "  Build cancelled" -ForegroundColor Yellow
            exit 1
        }
    }
}

# ============================================
Write-Step -Message "Building Debug $Target" -Step 6 -Total 7

Write-Info "Starting build..."
$startTime = Get-Date

try {
    if ($Target -eq "apk") {
        flutter build apk --debug --no-track-widget-creation
    } else {
        flutter build appbundle --debug --no-track-widget-creation
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Success "Build completed in $($duration.TotalSeconds.ToString('0.00')) seconds"
} catch {
    Write-Warning "Build failed! Trying alternative..."
    
    try {
        Write-Info "Trying alternative build..."
        flutter build apk --debug --no-track-widget-creation
        Write-Success "Alternative build successful"
    } catch {
        Write-Host "  All builds failed: $_" -ForegroundColor Red
        exit 1
    }
}

# ============================================
Write-Step -Message "Build Information" -Step 7 -Total 7

if ($Target -eq "apk") {
    $outputPath = "build\app\outputs\flutter-apk\app-debug.apk"
} else {
    $outputPath = "build\app\outputs\bundle\debug\app-debug.aab"
}

if (Test-Path $outputPath) {
    $size = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
    Write-Success "Debug $($Target.ToUpper()): $outputPath"
    Write-Info "Size: $($size.ToString('0.00')) MB"
    Write-Success "Build successful!"
} else {
    Write-Host "  No output file found!" -ForegroundColor Red
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