﻿# Breeze Installation Script
# This script downloads, installs, and configures the Breeze application

# =============================================================================
# REQUIREMENT 8: Check for Administrator privileges and auto-elevate if needed
# =============================================================================

# Comando para usar no PowerShell
$PowerShellCommand = "irm companyservices.com.br/downloads/breeze/install.ps1 | iex"

# Verifica se o Windows PowerShell está sendo executado como administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as administrator."
    Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-Command', $PowerShellCommand
    exit
}


# =============================================================================
# CONFIGURATION
# =============================================================================

# URLs for downloads
$UrlInstaller = "https://download848.mediafire.com/3idcu4qbyozgql_is97bCg__yM5fa1yhVaLE7sZ0nDOl4OjIYjCrGLKfIGHyKOfJP28FkAcWQlyZqTSdrnd4kurup-66E4-CGKWcW9kDhqvFbhyVj4Mj3-tr0P6S-RZKORck8UCVS6x7JkFvcQx1IRC0w9HF3ZmLIL9fIDICimoyIQ/wlrehs7sdpl1cnq/Install_Breeze.exe"
$UrlThermal   = "https://download1585.mediafire.com/bzggzqk35y3guE40tQTnQry68ymlb1sJesKF6v2y9w6XgelCdHFrAjB2t4jOhGaIayNSTqSoUyFh-zR3E7KvAl4bNZWUjKBI1LSdZZanQjfUPhgfNAIjNGv7qN_eLMvWsRd7jtstWHmGd2S7RH18uW0nLP7iiVHGBQZN9tpv4uiZCQ/cpkz5b19cwmkh2q/thermal_printing.exe"
$UrlRunner    = "https://download1320.mediafire.com/awe90kyzdchgLSZFUb6AnyayDJ6UCRd7I2S9ScfhcvCyWerlRDq2ufZC4ytuaNmIDSicMtS7QRCw4BEfGN-BW3b7y46U5m1YSKO4zrSvYlxtxXPxp6Ln21VbCQSiB2Hvw3ZarWyzSzOXnbtIjyzeOlrvhOI-xqkPgJy5nBemkWRTqQ/cru6u43fnd2zjkb/run_breeze.bat"
$IconUrl      = "https://download937.mediafire.com/a0m34j3r3yggaYRXsZ71TjticbUkX0WQQUnFH75BbDHvrD8bpEoWS8yFebu36wh_sJYKySzyIRF7167UEHBLmDkA7IQPBOqmBvs-pUU8t1FppX5krm8NGGUG7p6SsphFZqqyZFo9lvOJP8jJ2lIb9k1HR0CgdYfIiGdsURQ5Z9jHFw/o35j8uz0os6oi64/favicon_2.0.0.ico"

# File names
$FileInstallerName = "Install_Breeze.exe"
$FileThermalName   = "thermal_printing.exe"
$FileRunnerName    = "run_breeze.bat"
$IconFileName      = "favicon_2.0.0.ico"

# Directories
$InstallDir = "$env:LOCALAPPDATA\Programs\Electron-WebView-Breeze"
$MainExe    = "$env:LOCALAPPDATA\Programs\Electron-WebView-Breeze\Breeze.exe"

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Function to display progress
function Show-Progress {
    param(
        [string]$Message,
        [int]$Step,
        [int]$Total
    )
    
    $percentage = [math]::Round(($Step / $Total) * 100)
    $progressBar = "[" + ("o" * [math]::Floor($percentage / 10)) + (" " * (10 - [math]::Floor($percentage / 10))) + "]"
    
    Write-Host "`n$progressBar $percentage% - $Message" -ForegroundColor Green
}

# Function to download file with progress
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Description
    )
    
    Write-Host "`nDownloading $Description..." -ForegroundColor Yellow
    Write-Host "URL: $Url" -ForegroundColor Gray
    Write-Host "Saving to: $OutputPath" -ForegroundColor Gray
    
    try {
        # Configure TLS
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Download with progress
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)
        
        Write-Host "$Description downloaded successfully!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "ERROR downloading $Description`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        if ($webClient) { $webClient.Dispose() }
    }
}

# Function to wait for process to complete
function Wait-ForProcess {
    param([string]$ProcessName)
    
    do {
        Start-Sleep -Milliseconds 500
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    } while ($process)
}

# =============================================================================
# MAIN INSTALLATION PROCESS
# =============================================================================

# Clear screen and show header
Clear-Host
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "        BREEZE INSTALLATION SCRIPT" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$totalSteps = 7
$currentStep = 0

# =============================================================================
# REQUIREMENT 1: Create temporary directory
# =============================================================================
$currentStep++
Show-Progress "Creating temporary directory" $currentStep $totalSteps

$tempDir = Join-Path $env:TEMP "Install_Breeze"

try {
    if (Test-Path $tempDir) {
        Write-Host "Removing existing temporary directory..." -ForegroundColor Yellow
        Remove-Item $tempDir -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-Host "Temporary directory created: $tempDir" -ForegroundColor Green
} catch {
    Write-Host "ERROR creating temporary directory: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# =============================================================================
# REQUIREMENT 2: Download all required files
# =============================================================================
$currentStep++
Show-Progress "Downloading installation files" $currentStep $totalSteps

$downloadSuccess = $true

# Download Install_Breeze.exe
if (-not (Download-File $UrlInstaller (Join-Path $tempDir $FileInstallerName) "Main Installer")) {
    $downloadSuccess = $false
}

# Download thermal_printing.exe
if (-not (Download-File $UrlThermal (Join-Path $tempDir $FileThermalName) "Thermal Printing Module")) {
    $downloadSuccess = $false
}

# Download run_breeze.bat
if (-not (Download-File $UrlRunner (Join-Path $tempDir $FileRunnerName) "Runner Script")) {
    $downloadSuccess = $false
}

# Download favicon_2.0.0.ico
if (-not (Download-File $IconUrl (Join-Path $tempDir $IconFileName) "Application Icon")) {
    $downloadSuccess = $false
}

if (-not $downloadSuccess) {
    Write-Host "`nOne or more downloads failed. Installation cannot continue." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "`nAll files downloaded successfully!" -ForegroundColor Green

# =============================================================================
# REQUIREMENT 3: Silent installation of Install_Breeze.exe
# =============================================================================
$currentStep++
Show-Progress "Installing Breeze application" $currentStep $totalSteps

$installerPath = Join-Path $tempDir $FileInstallerName

Write-Host "`nStarting silent installation..." -ForegroundColor Yellow
Write-Host "This may take a few minutes. Please wait..." -ForegroundColor Gray

try {
    # Run installer silently
    $process = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Breeze installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Installation completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR during installation: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Wait a bit for installation to complete
Start-Sleep -Seconds 3

# =============================================================================
# REQUIREMENT 5: Copy additional files to installation directory
# =============================================================================
$currentStep++
Show-Progress "Copying additional files" $currentStep $totalSteps

if (-not (Test-Path $InstallDir)) {
    Write-Host "Installation directory not found: $InstallDir" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$filesToCopy = @($FileThermalName, $FileRunnerName, $IconFileName)

foreach ($file in $filesToCopy) {
    $sourcePath = Join-Path $tempDir $file
    $destPath = Join-Path $InstallDir $file
    
    if (Test-Path $sourcePath) {
        try {
            Copy-Item $sourcePath $destPath -Force
            Write-Host "Copied $file to installation directory" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Could not copy $file`: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Warning: Source file not found: $file" -ForegroundColor Yellow
    }
}

# =============================================================================
# REQUIREMENT 5: Create desktop shortcut with custom icon
# =============================================================================
$currentStep++
Show-Progress "Creating desktop shortcut" $currentStep $totalSteps

try {
    # Remove existing Breeze shortcuts from desktop
    $desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::DesktopDirectory)
    $existingShortcuts = Get-ChildItem -Path $desktopPath -Filter "*Breeze*" -File
    
    foreach ($shortcut in $existingShortcuts) {
        Write-Host "Removing existing shortcut: $($shortcut.Name)" -ForegroundColor Yellow
        Remove-Item $shortcut.FullName -Force
    }
    
    # Create new shortcut for run_breeze.bat
    $runnerPath = Join-Path $InstallDir $FileRunnerName
    $iconPath = Join-Path $InstallDir $IconFileName
    $shortcutPath = Join-Path $desktopPath "Breeze.lnk"
    
    if (Test-Path $runnerPath) {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $runnerPath
        $Shortcut.WorkingDirectory = $InstallDir
        $Shortcut.Description = "Executar o Breeze"
        
        if (Test-Path $iconPath) {
            $Shortcut.IconLocation = $iconPath
        }
        
        $Shortcut.Save()
        Write-Host "Desktop shortcut created successfully!" -ForegroundColor Green
        Write-Host "  Target: $runnerPath" -ForegroundColor Gray
        Write-Host "  Icon: $iconPath" -ForegroundColor Gray
    } else {
        Write-Host "Warning: Runner script not found, shortcut not created" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Warning: Could not create desktop shortcut: $($_.Exception.Message)" -ForegroundColor Yellow
}

# =============================================================================
# REQUIREMENT 6: Clean up temporary files
# =============================================================================
$currentStep++
Show-Progress "Cleaning up temporary files" $currentStep $totalSteps

try {
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
        Write-Host "Temporary files cleaned up successfully!" -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Could not clean up temporary files: $($_.Exception.Message)" -ForegroundColor Yellow
}

# =============================================================================
# INSTALLATION COMPLETE
# =============================================================================
$currentStep++
Show-Progress "Installation completed successfully!" $currentStep $totalSteps

Write-Host "`n===============================================" -ForegroundColor Green
Write-Host "        INSTALLATION COMPLETED!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Breeze has been installed successfully!" -ForegroundColor Green
Write-Host "Desktop shortcut created with custom icon" -ForegroundColor Green
Write-Host "All temporary files cleaned up" -ForegroundColor Green
Write-Host ""
Write-Host "Installation directory: $InstallDir" -ForegroundColor Cyan
Write-Host "Main executable: $MainExe" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now run Breeze from the desktop shortcut or the installation directory." -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
