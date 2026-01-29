# Flutter Build Scripts

Complete set of PowerShell scripts for Flutter development with storage optimization.

## 📁 Files Included

1. **`build_launcher.bat`** - Main menu launcher
2. **`build_debug.ps1`** - Debug build scripts (your optimized version)
3. **`build_release.ps1`** - Release build with signing
4. **`build_clean.ps1`** - Cleaning utilities
5. **`README.md`** - This documentation

## 🚀 Quick Start

1. Place all files in your Flutter project root
2. Run `build_launcher.bat`
3. Select options from the interactive menu

## ⚡ Direct PowerShell Usage

### Debug Builds:
```powershell
# Quick debug (no prompts)
.\build_debug.ps1 -QuickBuild

# Full debug (your original script)
.\build_debug.ps1

# Debug App Bundle
.\build_debug.ps1 -Target aab

# Build only (no cleaning)
.\build_debug.ps1 -BuildOnly

```
### Release Builds:
```powershell
# Quick release (no signing)
.\build_release.ps1 -QuickBuild

# Full release with signing
.\build_release.ps1

# Release APK only
.\build_release.ps1 -TargetPlatforms apk

# Minimal storage mode
.\build_release.ps1 -MinimalStorage

```

### Cleaning:
```powershell
# Project clean only (safe)
.\build_clean.ps1 -CleanProjectOnly

# Gradle cache only
.\build_clean.ps1 -CleanGradleOnly

# Full system clean (WARNING: Slow next build)
.\build_clean.ps1 -FullClean

```

## 🔧 Features
### Storage Optimization:
Selective cleaning - Only cleans what's necessary

Transforms metadata cleaning - Fixes Gradle cache issues

Storage monitoring - Warns before low disk space

Minimal storage mode - Uses --no-tree-shake-icons

### Debug Builds:
Quick build - Fast development cycles

Full build - Complete clean and rebuild

App Bundle support - Debug AAB builds

Storage warnings - Prevents disk space issues

### Release Builds:
Keystore management - Secure password handling

Multiple targets - APK, AAB, or both

Build.gradle verification - Checks signing config

Output management - Copy to custom directories

## 🛠️ Setup for Release Signing
### Generate a keystore:

```bash
keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias key
```
### Add signing to android/app/build.gradle:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## 📝 Notes
The scripts are storage-optimized - they don't delete entire caches unnecessarily

Transforms metadata cleaning specifically targets your Gradle corruption issue

Use -MinimalStorage flag when disk space is low

Never commit key.properties or keystore files to version control!

## 🆘 Troubleshooting
### "Execution Policy" Error:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Gradle Cache Issues:
Use the cleaning utilities or run:

```powershell
.\build_clean.ps1 -CleanGradleOnly
```
Low Disk Space:
```powershell
# Use minimal storage mode
.\build_debug.ps1 -QuickBuild
.\build_release.ps1 -MinimalStorage
```

## 📄 License
Free to use and modify for your projects.
