# ============================================
# FLUTTER BUILD ISSUE FIXER
# ============================================

param(
    [switch]$FixDependencies,
    [switch]$CheckKeystore,
    [switch]$FixGradle,
    [switch]$UpdateDependencies,
    [switch]$CheckConfig,
    [switch]$All
)

# ============================================
# CONFIGURATION & FUNCTIONS
# ============================================
$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Title)
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "    $Title" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message, [string]$Color = "Yellow")
    Write-Host "`n» $Message" -ForegroundColor $Color
}

function Write-Info {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor "Gray"
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  ⚠ $Message" -ForegroundColor "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor "Red"
}

function Fix-DuplicateClassIssue {
    Write-Header "Fixing Duplicate Class Error"
    
    Write-Step "Checking build.gradle configuration..."
    
    $buildGradlePath = "android/app/build.gradle"
    if (-not (Test-Path $buildGradlePath)) {
        Write-Error "build.gradle not found!"
        return $false
    }
    
    # Create backup
    $backupPath = "$buildGradlePath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $buildGradlePath $backupPath -Force
    Write-Success "Backup created: $backupPath"
    
    $content = Get-Content $buildGradlePath -Raw
    
    # Check current state
    $hasDebugEmbedding = $content -match "flutter_embedding_debug.*1\.0\.0"
    $hasReleaseEmbedding = $content -match "flutter_embedding_release.*1\.0\.0"
    $hasExclude = $content -match "exclude.*flutter_embedding_debug"
    
    Write-Info "Current state:"
    Write-Info "  Has debug embedding: $hasDebugEmbedding"
    Write-Info "  Has release embedding: $hasReleaseEmbedding"
    Write-Info "  Has exclude: $hasExclude"
    
    if ($hasDebugEmbedding -and $hasReleaseEmbedding -and -not $hasExclude) {
        Write-Step "Fixing duplicate dependencies..." -Color "Yellow"
        
        # Solution 1: Add exclude to configurations
        $excludeConfig = @"
    configurations {
        implementation {
            exclude group: 'io.flutter', module: 'flutter_embedding_debug'
        }
    }
"@

        $fixedContent = $content -replace "(android\s*\{)", "`$1`n$excludeConfig"

        # Solution 2: Fix dependencies block
        if ($content -match "dependencies\s*\{") {
            $dependencyFix = @"
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:`$kotlin_version"
    
    // Fixed: Use only release embedding with exclude
    implementation('io.flutter:flutter_embedding_release:1.0.0') {
        exclude group: 'io.flutter', module: 'flutter_embedding_debug'
    }
"@
            $fixedContent = $fixedContent -replace "(dependencies\s*\{)", "`$1`n$dependencyFix"
        }
        
        $fixedContent | Out-File $buildGradlePath -Encoding UTF8 -Force
        Write-Success "Fixed build.gradle configuration"
        
        # Clean caches
        Write-Step "Cleaning build caches..." -Color "Yellow"
        flutter clean 2>$null
        
        if (Test-Path "android") {
            Set-Location "android"
            ./gradlew clean 2>$null
            Set-Location ..
        }
        
        # Update dependencies
        Write-Step "Updating dependencies..." -Color "Yellow"
        flutter pub get
        
        Write-Success "Duplicate class issue should be fixed!"
        Write-Info "Try building again."
        return $true
    } elseif ($hasExclude) {
        Write-Success "Fix already applied!"
        return $true
    } else {
        Write-Warning "Configuration doesn't match expected pattern"
        Write-Info "Manual fix may be required."
        return $false
    }
}

function Check-KeystoreConfig {
    Write-Header "Checking Keystore Configuration"
    
    $keyPropertiesPath = "android/key.properties"
    $buildGradlePath = "android/app/build.gradle"
    
    Write-Step "Checking key.properties..."
    
    if (Test-Path $keyPropertiesPath) {
        Write-Success "key.properties exists"
        try {
            $content = Get-Content $keyPropertiesPath
            Write-Info "Contents:"
            foreach ($line in $content) {
                if ($line -match "password") {
                    Write-Info "  $($line.Split('=')[0])=********"
                } else {
                    Write-Info "  $line"
                }
            }
        } catch {
            Write-Error "Could not read key.properties"
        }
    } else {
        Write-Warning "key.properties not found"
        Write-Info "Create it with:"
        Write-Info "  storePassword=your_password"
        Write-Info "  keyPassword=your_password"
        Write-Info "  keyAlias=key"
        Write-Info "  storeFile=/path/to/keystore.jks"
    }
    
    Write-Step "Checking build.gradle signing config..."
    
    if (Test-Path $buildGradlePath) {
        $content = Get-Content $buildGradlePath -Raw
        
        if ($content -match "signingConfigs") {
            Write-Success "Signing config found in build.gradle"
        } else {
            Write-Warning "No signing config in build.gradle"
            Write-Info "Add signing config to android/app/build.gradle:"
            $signingConfig = @"
android {
    signingConfigs {
        release {
            storeFile file('keystore.jks')
            storePassword 'password'
            keyAlias 'key'
            keyPassword 'password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
"@
            Write-Info $signingConfig
        }
    } else {
        Write-Error "build.gradle not found"
    }
}

function Fix-GradleSync {
    Write-Header "Fixing Gradle Sync Issues"
    
    Write-Step "Cleaning Gradle cache..."
    
    # Clean various gradle caches
    $cachePaths = @(
        "$env:USERPROFILE\.gradle\caches",
        "android\.gradle",
        "build",
        "android\build",
        "android\app\build"
    )
    
    foreach ($path in $cachePaths) {
        if (Test-Path $path) {
            try {
                Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-Info "  Cleared: $path"
            } catch {
                Write-Warning "  Could not clear: $path"
            }
        }
    }
    
    Write-Step "Running Gradle clean..."
    
    if (Test-Path "android") {
        Set-Location "android"
        try {
            ./gradlew clean
            Write-Success "Gradle clean completed"
        } catch {
            Write-Error "Gradle clean failed"
        }
        Set-Location ..
    }
    
    Write-Step "Invalidating Android Studio caches..."
    Write-Info "If using Android Studio:"
    Write-Info "  1. File -> Invalidate Caches and Restart"
    Write-Info "  2. Click 'Invalidate and Restart'"
    
    Write-Success "Gradle sync fix applied"
}

function Update-FlutterDependencies {
    Write-Header "Updating Flutter Dependencies"
    
    Write-Step "Upgrading Flutter..."
    flutter upgrade
    
    Write-Step "Getting packages..."
    flutter pub get
    
    Write-Step "Upgrading packages..."
    flutter pub upgrade
    
    Write-Step "Running Flutter doctor..."
    flutter doctor -v
    
    Write-Success "Dependencies updated"
}

function Check-BuildConfig {
    Write-Header "Checking Build Configuration"
    
    Write-Step "Checking Flutter version..."
    flutter --version
    
    Write-Step "Checking pubspec.yaml..."
    if (Test-Path "pubspec.yaml") {
        $pubspec = Get-Content "pubspec.yaml" | Select-Object -First 20
        Write-Info "First 20 lines of pubspec.yaml:"
        $pubspec | ForEach-Object { Write-Info "  $_" }
    }
    
    Write-Step "Checking Android configuration..."
    if (Test-Path "android/app/build.gradle") {
        $buildGradle = Get-Content "android/app/build.gradle" | Select-Object -First 50
        Write-Info "First 50 lines of build.gradle:"
        $buildGradle | ForEach-Object { Write-Info "  $_" }
    }
    
    Write-Step "Checking for common issues..."
    
    # Check for duplicate embeddings
    if (Test-Path "android/app/build.gradle") {
        $content = Get-Content "android/app/build.gradle" -Raw
        if ($content -match "flutter_embedding_debug.*1\.0\.0" -and $content -match "flutter_embedding_release.*1\.0\.0") {
            Write-Warning "Potential duplicate embedding found"
        }
    }
    
    Write-Success "Configuration check complete"
}

# ============================================
# MAIN EXECUTION
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "    FLUTTER BUILD FIXER                    " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if ($All -or (-not ($FixDependencies -or $CheckKeystore -or $FixGradle -or $UpdateDependencies -or $CheckConfig))) {
    # Run all fixes
    Fix-DuplicateClassIssue
    Check-KeystoreConfig
    Fix-GradleSync
    Update-FlutterDependencies
    Check-BuildConfig
    
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "    ALL FIXES COMPLETED                  " -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
} else {
    if ($FixDependencies) { Fix-DuplicateClassIssue }
    if ($CheckKeystore) { Check-KeystoreConfig }
    if ($FixGradle) { Fix-GradleSync }
    if ($UpdateDependencies) { Update-FlutterDependencies }
    if ($CheckConfig) { Check-BuildConfig }
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")