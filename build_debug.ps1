# ============================================
# FLUTTER DEBUG BUILD SCRIPT FOR WINDOWS
# ============================================

Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    Flutter Debug Build Script                ║" -ForegroundColor Cyan
Write-Host "║    Starting build process...                 ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan

# ============================================
# STEP 1: KILL ALL RUNNING PROCESSES
# ============================================
Write-Host "`n[1/8] Killing running processes..." -ForegroundColor Yellow

$processes = @("java", "javaw", "gradle", "adb", "dart", "flutter", "AndroidStudio")
foreach ($proc in $processes) {
    Get-Process $proc* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Killed $proc processes" -ForegroundColor Green
}
Start-Sleep -Seconds 2

# ============================================
# STEP 2: CLEAN FLUTTER CACHE
# ============================================
Write-Host "`n[2/8] Cleaning Flutter cache..." -ForegroundColor Yellow

# Clean Flutter cache
Write-Host "  Running flutter clean..." -ForegroundColor Gray
flutter clean

# Clean Pub cache
Write-Host "  Running flutter pub cache repair..." -ForegroundColor Gray
flutter pub cache repair

# ============================================
# STEP 3: CLEAN GRADLE CACHE
# ============================================
Write-Host "`n[3/8] Cleaning Gradle cache..." -ForegroundColor Yellow

# Try to clean Gradle cache
$gradleCache = "$env:USERPROFILE\.gradle\caches"
if (Test-Path $gradleCache) {
    Write-Host "  Deleting Gradle cache..." -ForegroundColor Gray
    Remove-Item -Path $gradleCache -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Gradle cache cleaned" -ForegroundColor Green
} else {
    Write-Host "  Gradle cache not found" -ForegroundColor Gray
}

# ============================================
# STEP 4: CLEAN ANDROID BUILD CACHE
# ============================================
Write-Host "`n[4/8] Cleaning Android build cache..." -ForegroundColor Yellow

# Clean Android build directories
$buildDirs = @("build", ".gradle", ".idea")
foreach ($dir in $buildDirs) {
    $path = "android/$dir"
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Cleaned $dir" -ForegroundColor Green
    }
}

# ============================================
# STEP 5: GET DEPENDENCIES
# ============================================
Write-Host "`n[5/8] Getting dependencies..." -ForegroundColor Yellow

# Get Flutter packages
Write-Host "  Running flutter pub get..." -ForegroundColor Gray
flutter pub get

# Get Android dependencies
Write-Host "  Getting Android dependencies..." -ForegroundColor Gray
Set-Location android
./gradlew clean
Set-Location ..

# ============================================
# STEP 6: RUN FLUTTER DOCTOR
# ============================================
Write-Host "`n[6/8] Checking Flutter environment..." -ForegroundColor Yellow
flutter doctor -v

# ============================================
# STEP 7: BUILD DEBUG APK
# ============================================
Write-Host "`n[7/8] Building Debug APK..." -ForegroundColor Yellow

# Build with verbose logging
Write-Host "  Starting build process..." -ForegroundColor Gray
$startTime = Get-Date

# Build debug APK
try {
    flutter build apk --debug --verbose
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Host "  ✓ Build completed in $($duration.TotalSeconds.ToString('0.00')) seconds" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Build failed!" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# STEP 8: DISPLAY BUILD INFO
# ============================================
Write-Host "`n[8/8] Build Information" -ForegroundColor Yellow

# Show APK location
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
    $apkSize = (Get-Item $apkPath).Length / 1MB
    Write-Host "  APK Location: $apkPath" -ForegroundColor Green
    Write-Host "  APK Size: $($apkSize.ToString('0.00')) MB" -ForegroundColor Green
    Write-Host "  Build successful! ✓" -ForegroundColor Green
} else {
    Write-Host "  APK not found!" -ForegroundColor Red
}

# ============================================
# COMPLETION MESSAGE
# ============================================
Write-Host "`n╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    Build Process Complete!                    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan

pause