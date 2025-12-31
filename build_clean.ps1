# ============================================
# FLUTTER CLEANING UTILITIES
# ============================================

param(
    [switch]$FullClean,
    [switch]$CleanGradleOnly,
    [switch]$CleanFlutterOnly,
    [switch]$CleanProjectOnly,
    [switch]$NoPrompt
)

# ============================================
# FUNCTIONS
# ============================================
function Write-Header {
    param([string]$Title)
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    $Title" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
}

function Get-DirectorySize {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0 }
    try {
        $size = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        return [math]::Round($size / 1MB, 2)
    } catch { return 0 }
}

function Confirm-Action {
    param([string]$Message)
    if ($NoPrompt) { return $true }
    Write-Host "$Message" -ForegroundColor Yellow -NoNewline
    $response = Read-Host " (y/N)"
    return ($response -eq 'y')
}

# ============================================
# MAIN LOGIC
# ============================================
if ($FullClean) {
    Write-Header "FULL SYSTEM CLEAN"
    
    Write-Host "This will clean:" -ForegroundColor Yellow
    Write-Host "  • Flutter build cache" -ForegroundColor Gray
    Write-Host "  • Gradle cache (ALL versions)" -ForegroundColor Gray
    Write-Host "  • Android build directories" -ForegroundColor Gray
    Write-Host "  • Pub cache" -ForegroundColor Gray
    Write-Host ""
    Write-Host "WARNING: Next build will be SLOW!" -ForegroundColor Red
    
    if (-not (Confirm-Action "Are you sure?")) {
        Write-Host "Clean cancelled" -ForegroundColor Yellow
        exit 0
    }
    
    # Kill processes
    Write-Host "`nStopping processes..." -ForegroundColor Yellow
    Get-Process java*, javaw*, gradle*, dart* -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Clean Flutter
    Write-Host "Cleaning Flutter..." -ForegroundColor Yellow
    flutter clean
    flutter pub cache repair
    
    # Clean Gradle
    $gradleCache = "$env:USERPROFILE\.gradle\caches"
    if (Test-Path $gradleCache) {
        $size = Get-DirectorySize $gradleCache
        Write-Host "Cleaning Gradle cache ($size MB)..." -ForegroundColor Yellow
        Remove-Item $gradleCache -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Clean Android
    Write-Host "Cleaning Android..." -ForegroundColor Yellow
    if (Test-Path "android\build") {
        Remove-Item "android\build" -Recurse -Force
    }
    if (Test-Path "android\.gradle") {
        Remove-Item "android\.gradle" -Recurse -Force
    }
    
    Write-Host "`nFull clean completed!" -ForegroundColor Green
}
elseif ($CleanGradleOnly) {
    Write-Header "GRADLE CACHE CLEAN"
    
    $gradleCache = "$env:USERPROFILE\.gradle\caches"
    if (Test-Path $gradleCache) {
        $size = Get-DirectorySize $gradleCache
        Write-Host "Gradle cache size: $size MB" -ForegroundColor Gray
        
        if ($size -gt 100) {
            Write-Host "Large cache detected!" -ForegroundColor Yellow
            
            if (Confirm-Action "Clean ALL Gradle cache?") {
                Remove-Item $gradleCache -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Gradle cache cleaned" -ForegroundColor Green
            } else {
                # Clean only transforms
                $transformsPath = "$gradleCache\transforms-*"
                if (Test-Path $transformsPath) {
                    if (Confirm-Action "Clean only transforms metadata?") {
                        Remove-Item $transformsPath -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "Transforms metadata cleaned" -ForegroundColor Green
                    }
                }
            }
        } else {
            if (Confirm-Action "Clean Gradle cache?") {
                Remove-Item $gradleCache -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Gradle cache cleaned" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Gradle cache not found" -ForegroundColor Gray
    }
}
elseif ($CleanFlutterOnly) {
    Write-Header "FLUTTER CACHE CLEAN"
    
    Write-Host "Cleaning Flutter caches..." -ForegroundColor Yellow
    flutter clean
    Write-Host "Flutter project cleaned" -ForegroundColor Green
    
    if (Confirm-Action "Also clean pub cache?") {
        flutter pub cache repair
        Write-Host "Pub cache repaired" -ForegroundColor Green
    }
}
elseif ($CleanProjectOnly) {
    Write-Header "PROJECT CLEAN ONLY"
    
    Write-Host "Cleaning project build files..." -ForegroundColor Yellow
    flutter clean
    
    if (Test-Path "android\build") {
        Remove-Item "android\build" -Recurse -Force
        Write-Host "Android build cleaned" -ForegroundColor Green
    }
    
    Write-Host "Project cleaned (caches preserved)" -ForegroundColor Green
}
else {
    Write-Header "CLEANING UTILITIES"
    
    Write-Host "Available options:" -ForegroundColor Yellow
    Write-Host "  -FullClean       : Clean everything (WARNING: Slow next build)" -ForegroundColor Gray
    Write-Host "  -CleanGradleOnly : Clean only Gradle cache" -ForegroundColor Gray
    Write-Host "  -CleanFlutterOnly: Clean only Flutter cache" -ForegroundColor Gray
    Write-Host "  -CleanProjectOnly: Clean only project files (safe)" -ForegroundColor Gray
    Write-Host "  -NoPrompt        : Skip confirmation prompts" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Example: .\build_clean.ps1 -CleanProjectOnly" -ForegroundColor Cyan
}

if (-not $NoPrompt) {
    Write-Host "`nPress any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}