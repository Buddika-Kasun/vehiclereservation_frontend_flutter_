# ============================================
# FLUTTER RELEASE BUILD WITH SIGNING
# ============================================

param(
    [string]$KeystorePath = "",
    [string]$KeyAlias = "",
    [string]$TargetPlatforms = "apk",
    [switch]$SkipPrompts,
    [switch]$MinimalStorage,
    [string]$OutputDir = "",
    [switch]$QuickBuild,
    [switch]$NoSigning,
    [switch]$FixDependencies
)

# ============================================
# CONFIGURATION & FUNCTIONS
# ============================================
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message, [int]$Step, [int]$Total, [string]$Color = "Yellow")
    Write-Host "`n[$Step/$Total] $Message" -ForegroundColor $Color
}

function Write-Info {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor "Gray"
}

function Write-Success {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ERROR: $Message" -ForegroundColor "Red"
}

function Get-SecurePassword {
    param([string]$Prompt)
    if ($SkipPrompts) { return "" }
    $secure = Read-Host "$Prompt" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    return $password
}

function Fix-DuplicateDependencies {
    Write-Info "Fixing duplicate dependency issues..."
    
    $buildGradlePath = "android/app/build.gradle"
    if (-not (Test-Path $buildGradlePath)) {
        Write-Error "build.gradle not found!"
        return $false
    }
    
    # Create backup
    $backupPath = "$buildGradlePath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $buildGradlePath $backupPath -Force
    Write-Success "Backup created: $backupPath"
    
    # Read current content
    $content = Get-Content $buildGradlePath -Raw
    
    # Check if fix is already applied
    if ($content -match "exclude group: 'io\.flutter', module: 'flutter_embedding_debug'") {
        Write-Success "Dependency fix already applied"
        return $true
    }
    
    # Apply the fix for duplicate classes
    $fixApplied = $false
    
    # Method 1: Add configurations block
    if ($content -match "android\s*\{") {
        $configBlock = @"

    configurations {
        implementation {
            exclude group: 'io.flutter', module: 'flutter_embedding_debug'
        }
    }
"@

        $content = $content -replace "(android\s*\{)", "`$1`n$configBlock"
        $fixApplied = $true
        Write-Info "Added configurations block"
    }
    
    # Method 2: Fix dependencies section
    $dependenciesBlock = @"

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:`$kotlin_version"
    
    // Add this line to exclude duplicate embedding
    implementation('io.flutter:flutter_embedding_release:1.0.0') {
        exclude group: 'io.flutter', module: 'flutter_embedding_debug'
    }
    
    // Your other dependencies below...
}
"@

    if ($content -match "dependencies\s*\{") {
        # Replace dependencies block
        $content = $content -replace "dependencies\s*\{[^}]+\}", $dependenciesBlock
        $fixApplied = $true
        Write-Info "Fixed dependencies block"
    }
    
    # Save changes
    $content | Out-File $buildGradlePath -Encoding UTF8 -Force
    
    if ($fixApplied) {
        Write-Success "Duplicate dependency fix applied successfully!"
        return $true
    } else {
        Write-Warning "Could not automatically fix dependencies"
        return $false
    }
}

function Clean-GradleCache {
    Write-Info "Cleaning Gradle cache to resolve conflicts..."
    
    try {
        # Clean Android build
        if (Test-Path "android") {
            Set-Location "android"
            ./gradlew clean 2>$null
            Set-Location ..
            Write-Success "Android Gradle cleaned"
        }
        
        # Remove build directories
        $dirsToClean = @(
            "build",
            "android/build",
            "android/app/build",
            "$env:USERPROFILE\.gradle\caches\transforms-2",
            "$env:USERPROFILE\.gradle\caches\modules-2"
        )
        
        foreach ($dir in $dirsToClean) {
            if (Test-Path $dir) {
                Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Info "  Cleared: $dir"
            }
        }
        
        Write-Success "Gradle cache cleaned"
        return $true
    } catch {
        Write-Warning "Could not clean Gradle cache: $_"
        return $false
    }
}

function Check-AndroidBuildGradle {
    Write-Info "Checking Android build configuration..."
    
    $buildGradlePath = "android/app/build.gradle"
    if (-not (Test-Path $buildGradlePath)) {
        Write-Error "build.gradle not found at $buildGradlePath"
        return $false
    }
    
    $content = Get-Content $buildGradlePath -Raw
    
    # Check for common issues
    $issues = @()
    
    if ($content -match "flutter_embedding_debug.*1\.0\.0" -and $content -match "flutter_embedding_release.*1\.0\.0") {
        $issues += "Both debug and release embeddings found - will cause duplicate class error"
    }
    
    if ($content -notmatch "exclude.*flutter_embedding_debug") {
        $issues += "Missing exclude for flutter_embedding_debug"
    }
    
    if ($issues.Count -gt 0) {
        Write-Warning "Found $($issues.Count) issue(s):"
        foreach ($issue in $issues) {
            Write-Warning "  • $issue"
        }
        return $false
    } else {
        Write-Success "Android build configuration looks good"
        return $true
    }
}

# ============================================
# HEADER
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "    FLUTTER RELEASE BUILD                  " -ForegroundColor Cyan

if ($NoSigning) {
    Write-Host "    (Unsigned Build Mode)                " -ForegroundColor Yellow
} elseif ($QuickBuild) {
    Write-Host "    (Quick Build Mode)                   " -ForegroundColor Green
} elseif ($FixDependencies) {
    Write-Host "    (Fix Dependencies Mode)              " -ForegroundColor Magenta
}

if ($MinimalStorage) {
    Write-Host "    (Minimal Storage Mode)                " -ForegroundColor Cyan
}
Write-Host "============================================" -ForegroundColor Cyan

# ============================================
# QUICK RELEASE BUILD (Option 1)
# ============================================
if ($QuickBuild) {
    Write-Step -Message "Quick Release Build" -Step 1 -Total 3
    
    Write-Info "Cleaning project..."
    try {
        flutter clean 2>$null
        Write-Success "Project cleaned"
    } catch {
        Write-Warning "Clean command failed, continuing..."
    }
    
    Write-Info "Getting dependencies..."
    flutter pub get 2>$null
    
    # Quick fix check
    Check-AndroidBuildGradle | Out-Null
    
    Write-Info "Building release..."
    $startTime = Get-Date
    $buildResults = @()
    
    if ($TargetPlatforms -eq "apk" -or $TargetPlatforms -eq "apk,aab") {
        Write-Info "Building APK..."
        try {
            if ($NoSigning) {
                flutter build apk --release --no-tree-shake-icons
            } else {
                flutter build apk --release
            }
            
            $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
            if (Test-Path $apkPath) {
                $size = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
                $buildResults += "APK: $apkPath ($size MB)"
                Write-Success "APK built successfully"
            }
        } catch {
            Write-Error "APK build failed: $_"
        }
    }
    
    if ($TargetPlatforms -eq "aab" -or $TargetPlatforms -eq "apk,aab") {
        Write-Info "Building AAB..."
        try {
            if ($NoSigning) {
                flutter build appbundle --release --no-tree-shake-icons
            } else {
                flutter build appbundle --release
            }
            
            $aabPath = "build\app\outputs\bundle\release\app-release.aab"
            if (Test-Path $aabPath) {
                $size = [math]::Round((Get-Item $aabPath).Length / 1MB, 2)
                $buildResults += "AAB: $aabPath ($size MB)"
                Write-Success "AAB built successfully"
            }
        } catch {
            Write-Error "AAB build failed: $_"
        }
    }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    Write-Success "Build completed in $($duration.ToString('0.00')) seconds"
    
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "    Quick Release Complete!              " -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    
    if ($buildResults.Count -eq 0) {
        Write-Warning "No builds were successful. Try running with -FixDependencies"
    }
    
    if (-not $SkipPrompts) { pause }
    exit 0
}

# ============================================
# DEPENDENCY FIX MODE
# ============================================
if ($FixDependencies) {
    Write-Step -Message "Fixing Dependencies" -Step 1 -Total 3
    
    # Clean first
    Write-Info "Cleaning project..."
    flutter clean 2>$null
    
    # Apply fixes
    $fixResult = Fix-DuplicateDependencies
    $cleanResult = Clean-GradleCache
    
    Write-Info "Getting fresh dependencies..."
    flutter pub get
    
    if ($fixResult -and $cleanResult) {
        Write-Success "`nDependencies fixed successfully!"
        Write-Info "You can now run the build again."
    } else {
        Write-Warning "`nSome fixes may not have been applied."
        Write-Info "Check the build.gradle file manually."
    }
    
    if (-not $SkipPrompts) { pause }
    exit 0
}

# ============================================
# FULL RELEASE BUILD
# ============================================
Write-Step -Message "System Check" -Step 1 -Total 10

# Check disk space
try {
    $drive = Get-PSDrive C
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    Write-Info "Disk C: $freeGB GB free"
    
    if ($freeGB -lt 5 -and -not $MinimalStorage) {
        Write-Warning "Low disk space! Consider -MinimalStorage flag"
        if (-not $SkipPrompts) {
            $continue = Read-Host "  Continue anyway? (y/N)"
            if ($continue -ne 'y') { exit 1 }
        }
    }
} catch {
    Write-Warning "Could not check disk space"
}

# ============================================
Write-Step -Message "Process Management" -Step 2 -Total 10

Write-Info "Stopping build processes..."
$processes = @("java", "javaw", "gradle", "dart")
foreach ($proc in $processes) {
    Get-Process $proc* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# ============================================
Write-Step -Message "Project Cleaning" -Step 3 -Total 10

Write-Info "Cleaning Flutter project..."
flutter clean

Write-Info "Cleaning Android build..."
if (Test-Path "android\build") {
    Remove-Item "android\build" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Success "Android build cleaned"
}

# ============================================
Write-Step -Message "Dependency Fix" -Step 4 -Total 10

Write-Info "Checking for duplicate dependency issues..."
$configOk = Check-AndroidBuildGradle

if (-not $configOk) {
    Write-Warning "Potential duplicate class issue detected!"
    if (-not $SkipPrompts) {
        $fix = Read-Host "  Attempt automatic fix? (Y/n)"
        if ($fix -ne 'n') {
            Fix-DuplicateDependencies | Out-Null
            Clean-GradleCache | Out-Null
        }
    } else {
        Fix-DuplicateDependencies | Out-Null
        Clean-GradleCache | Out-Null
    }
}

# ============================================
Write-Step -Message "Keystore Setup" -Step 5 -Total 10

if (-not $NoSigning) {
    if ([string]::IsNullOrWhiteSpace($KeystorePath)) {
        if ($SkipPrompts) {
            Write-Error "Keystore path required with -SkipPrompts"
            exit 1
        }
        
        $KeystorePath = Read-Host "  Enter keystore path (full path to .keystore/.jks)"
    }

    if (-not (Test-Path $KeystorePath)) {
        Write-Error "Keystore not found: $KeystorePath"
        Write-Host "  Create one with: keytool -genkey -v -keystore `"$KeystorePath`" -keyalg RSA -keysize 2048 -validity 10000 -alias release_key" -ForegroundColor Yellow
        exit 1
    }

    if ([string]::IsNullOrWhiteSpace($KeyAlias)) {
        if ($SkipPrompts) {
            $KeyAlias = "key"
        } else {
            $KeyAlias = Read-Host "  Enter key alias (default: 'key')"
            if ([string]::IsNullOrWhiteSpace($KeyAlias)) { $KeyAlias = "key" }
        }
    }

    if ($SkipPrompts) {
        $storePassword = ""
        $keyPassword = ""
    } else {
        $storePassword = Get-SecurePassword "  Enter keystore password"
        $keyPassword = Get-SecurePassword "  Enter key password (Enter if same)"
        if ([string]::IsNullOrWhiteSpace($keyPassword)) { $keyPassword = $storePassword }
    }

    Write-Success "Keystore configured"
} else {
    Write-Info "Skipping signing (NoSigning flag set)"
}

# ============================================
Write-Step -Message "Build Configuration" -Step 6 -Total 10

if (-not $NoSigning) {
    # Create key.properties for signing
    $keyPropertiesContent = @"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$KeyAlias
storeFile=$($KeystorePath -replace '\\', '/')
"@

    $keyPropertiesPath = "android/key.properties"
    $keyPropertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding ASCII -Force
    Write-Success "Created key.properties"
} else {
    Write-Info "No signing configuration needed"
}

# ============================================
Write-Step -Message "Dependencies" -Step 7 -Total 10

Write-Info "Getting Flutter packages..."
flutter pub get --offline 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Info "Fetching online..."
    flutter pub get
}

# ============================================
Write-Step -Message "Build Targets" -Step 8 -Total 10

$buildAPK = $TargetPlatforms -match "apk"
$buildAAB = $TargetPlatforms -match "aab"

Write-Info "Building targets:"
if ($buildAPK) { Write-Info "  ✓ Release APK" }
if ($buildAAB) { Write-Info "  ✓ Release App Bundle (AAB)" }

# ============================================
Write-Step -Message "Release Build" -Step 9 -Total 10

$buildStartTime = Get-Date
$buildResults = @()
$buildSuccess = $true

if ($buildAPK) {
    Write-Info "Building Release APK..."
    try {
        $buildArgs = @("build", "apk", "--release")
        if ($MinimalStorage) { $buildArgs += "--no-tree-shake-icons" }
        
        Write-Info "Running: flutter $buildArgs"
        flutter $buildArgs
        
        $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
        if (Test-Path $apkPath) {
            $size = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
            $buildResults += "APK: $apkPath ($size MB)"
            Write-Success "APK built successfully"
        } else {
            Write-Error "APK not found after build"
            $buildSuccess = $false
        }
    } catch {
        Write-Error "APK build failed: $_"
        $buildSuccess = $false
    }
}

if ($buildAAB) {
    Write-Info "Building Release App Bundle (AAB)..."
    try {
        $buildArgs = @("build", "appbundle", "--release")
        if ($MinimalStorage) { $buildArgs += "--no-tree-shake-icons" }
        
        Write-Info "Running: flutter $buildArgs"
        flutter $buildArgs
        
        $aabPath = "build\app\outputs\bundle\release\app-release.aab"
        if (Test-Path $aabPath) {
            $size = [math]::Round((Get-Item $aabPath).Length / 1MB, 2)
            $buildResults += "AAB: $aabPath ($size MB)"
            Write-Success "AAB built successfully"
        } else {
            Write-Error "AAB not found after build"
            $buildSuccess = $false
        }
    } catch {
        Write-Error "AAB build failed: $_"
        $buildSuccess = $false
    }
}

$buildDuration = (Get-Date) - $buildStartTime
Write-Info "Build time: $($buildDuration.TotalSeconds.ToString('0.00')) seconds"

# ============================================
Write-Step -Message "Final Report" -Step 10 -Total 10

Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "BUILD SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

if ($buildResults.Count -gt 0) {
    Write-Host "Generated files:" -ForegroundColor Green
    foreach ($result in $buildResults) {
        Write-Host "  • $result" -ForegroundColor Green
    }
    
    if (-not [string]::IsNullOrWhiteSpace($OutputDir) -and (Test-Path $OutputDir)) {
        Write-Info "Copying outputs to: $OutputDir"
        if (Test-Path $apkPath) { Copy-Item $apkPath $OutputDir -Force }
        if (Test-Path $aabPath) { Copy-Item $aabPath $OutputDir -Force }
    }
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    
    if (-not $buildSuccess) {
        Write-Host "`nTROUBLESHOOTING:" -ForegroundColor Yellow
        Write-Host "1. Run with -FixDependencies flag" -ForegroundColor Yellow
        Write-Host "2. Try: flutter clean && flutter pub get" -ForegroundColor Yellow
        Write-Host "3. Check android/app/build.gradle for duplicate dependencies" -ForegroundColor Yellow
    }
}

# Clean sensitive data
if (-not $NoSigning) {
    $storePassword = $null
    $keyPassword = $null
}

Write-Host "`n============================================" -ForegroundColor Cyan
if ($buildSuccess) {
    Write-Host "    Release Build Complete!                 " -ForegroundColor Cyan
} else {
    Write-Host "    Build Completed with Errors            " -ForegroundColor Red
}
Write-Host "============================================" -ForegroundColor Cyan

if (-not $SkipPrompts) { pause }