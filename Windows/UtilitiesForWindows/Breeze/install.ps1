﻿# install.ps1 - Executa o script de instalação do Breeze.
# Autor/Manutenção: Marcos Aurélio R. da Silva <systemboys@hotmail.com>
# Licença: GPL.
# Histórico:
# v1.0.0 2025-10-05 12h28 - Versão inicial.

param(
    [string]$OrigDesktop  # caminho do Desktop do usuário não-elevado (preenchido no relançamento)
)

# =====================================================================
# =================== SESSÃO DE VARIÁVEIS DE CONFIGURAÇÃO =============
# 
# Esta sessão centraliza todas as variáveis que podem ser alteradas para
# manutenção futura do script, como URLs de download, nomes de atalhos,
# nomes de arquivos, caminhos de instalação, etc. 
# 
# Para atualizar links, nomes ou caminhos, altere apenas nesta área.
# =====================================================================

# URLs de download
$Config = @{
    UrlInstaller = "https://onedrive.live.com/personal/fe54bd7ca85fc328/_layouts/15/download.aspx?UniqueId=c851b796%2D54a7%2D4850%2Db3f1%2Db16bd454ffa9"
    UrlThermal   = "https://onedrive.live.com/personal/fe54bd7ca85fc328/_layouts/15/download.aspx?UniqueId=a85fc328%2Dbd7c%2D2054%2D80fe%2Dc23702000000"
    UrlRunner    = "https://www.companyservices.com.br/gti-sis-stock-5/run_breeze.bat"
    IconUrl      = "https://github.com/systemboys/SiSFloatBase_image/raw/main/Logo/ICOs/favicon_2.0.0.ico"

    # Nomes de arquivos temporários
    FileInstallerName = "Install_Breeze.exe"
    FileThermalName   = "thermal_printing.exe"
    FileRunnerName    = "run_breeze.bat"
    IconFileName      = "favicon_2.0.0.ico"

    # Nome do diretório do programa
    ProgramDirName    = "Breeze"

    # Nome do atalho na área de trabalho
    ShortcutName      = "Breeze.lnk"

    # Descrição do atalho
    ShortcutDescription = "Executar o Breeze"
}

# =====================================================================
# =================== FIM DA SESSÃO DE VARIÁVEIS ======================
# =====================================================================

# ------------------ Config de Log/Hashes ------------------
$logDir = Join-Path $env:ProgramData "GTi\SiSStock\Logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir ("install_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

# (Opcional) Preencha para validar integridade dos downloads:
$ExpectedHash = @{
    "installer" = ""  # Ex.: "D6B8F5...." (SHA256)
    "thermal"   = ""
    "runner"    = ""
}

try { Start-Transcript -Path $logFile -Append -Force | Out-Null } catch {}

# ------------------ Utilidades ------------------
function Compute-Hash {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Ensure-Hash {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Expected # pode ser vazio; se vazio só registra
    )
    $hash = Compute-Hash -Path $Path
    Write-Host "SHA256 ($([IO.Path]::GetFileName($Path))): $hash"
    if ($Expected -and ($hash -ne $Expected.ToUpperInvariant())) {
        Write-Host "Hash mismatch for $Path. Expected: $Expected, Got: $hash"
        throw "Integrity check failed for $Path"
    }
}

function Start-BitsDownloadWithProgress {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Destination,
        [string]$Label = "Downloading"
    )

    # Garante diretório
    $destDir = Split-Path -Path $Destination -Parent
    if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory | Out-Null }

    try {
        Import-Module BitsTransfer -ErrorAction SilentlyContinue
        $job = Start-BitsTransfer -Source $Url -Destination $Destination -Asynchronous -ErrorAction Stop

        do {
            Start-Sleep -Milliseconds 250
            $job = Get-BitsTransfer -Id $job.Id -ErrorAction SilentlyContinue
            if (-not $job) { break }

            $total = [math]::Max(1, [double]$job.BytesTotal)
            $done  = [double]$job.BytesTransferred
            $pct   = [int]([math]::Round(($done/$total)*100,0))
            Write-Progress -Activity $Label -Status "$pct% complete" -PercentComplete $pct
        } while ($job.JobState -in 'Connecting','Transferring','Queued')

        if ($job -and $job.JobState -eq 'Transferred') {
            Complete-BitsTransfer -BitsJob $job
        } elseif ($job) {
            throw "BITS failed: $($job.JobState)"
        } else {
            throw "BITS job not found or failed to start."
        }

        Write-Progress -Activity $Label -Completed
    } catch {
        # Fallback simples: IWR (sem progresso granular)
        Write-Progress -Activity $Label -Status "Fallback transfer..." -PercentComplete 0
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
        Write-Progress -Activity $Label -Completed
    }
}

# ------------------ Autoelevação (robusta) ------------------
$currIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($currIdentity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as administrator."

    $cmd = 'Invoke-RestMethod -Uri "https://raw.githubusercontent.com/systemboys/_GTi_Support_/refs/heads/main/Windows/UtilitiesForWindows/Breeze/install.ps1" | Invoke-Expression'
    $bytes = [Text.Encoding]::Unicode.GetBytes($cmd)
    $b64   = [Convert]::ToBase64String($bytes)

    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy","Bypass",
        "-EncodedCommand",$b64
    )
    exit
}

# ------------------ Ambiente ------------------
try {
    $Host.UI.RawUI.BackgroundColor = "Black"
    Clear-Host
} catch {}

try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
} catch {
    try { Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force } catch {}
}

# ------------------ URLs e caminhos (usando sessão de variáveis) ------------------
$urlInstaller = $Config.UrlInstaller
$urlThermal   = $Config.UrlThermal
$urlRunner    = $Config.UrlRunner
$iconUrl      = $Config.IconUrl

$tempDir       = $env:TEMP
$fileInstaller = Join-Path $tempDir $Config.FileInstallerName
$fileThermal   = Join-Path $tempDir $Config.FileThermalName
$fileRunnerTmp = Join-Path $tempDir $Config.FileRunnerName
$iconPath      = Join-Path $env:USERPROFILE $Config.IconFileName

$programDir = Join-Path ${env:ProgramFiles(x86)} $Config.ProgramDirName
$fileRunner = Join-Path $programDir $Config.FileRunnerName
$programExe = Join-Path $programDir $Config.FileThermalName

# Desktop (preserva Desktop do usuário original quando elevou)
if ([string]::IsNullOrWhiteSpace($OrigDesktop)) {
    $desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::DesktopDirectory)
} else {
    $desktopPath = $OrigDesktop
}
$shortcutPath = Join-Path $desktopPath $Config.ShortcutName

# ------------------ Download e instalação ------------------
Write-Host "Breeze doesn't exist on Windows! Downloading the installer..."
Write-Host "Please wait for the download and installation procedure!"

Start-BitsDownloadWithProgress -Url $urlInstaller -Destination $fileInstaller -Label "Downloading Breeze installer"
Write-Host "Download completed successfully!"

# Verifica hash (opcional)
Ensure-Hash -Path $fileInstaller -Expected $ExpectedHash.installer

Write-Host "`nRunning the Breeze installer..."
$installerArgs = @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/SP-')
$proc = Start-Process -FilePath $fileInstaller -ArgumentList $installerArgs -NoNewWindow -PassThru

# Progresso "indeterminado" baseado no tempo
$start = Get-Date
while (-not $proc.HasExited) {
    $elapsed = (Get-Date) - $start
    $pct = [int](($elapsed.TotalSeconds % 20) / 20 * 100)  # 0..99 em loop
    Write-Progress -Activity "Installing Breeze" -Status "Running... ($([int]$elapsed.TotalSeconds)s elapsed)" -PercentComplete $pct
    Start-Sleep -Milliseconds 500
}
Write-Progress -Activity "Installing Breeze" -Completed

Write-Host "`nDeleting the Breeze installer..."
if (Test-Path $fileInstaller) { Remove-Item -Path $fileInstaller -Force -ErrorAction SilentlyContinue }

# Garante diretório do programa
if (-not (Test-Path $programDir)) {
    New-Item -ItemType Directory -Path $programDir | Out-Null
}

# Baixa thermal_printing e runner com progresso
Start-BitsDownloadWithProgress -Url $urlThermal -Destination $fileThermal -Label "Downloading thermal printing component"
Ensure-Hash -Path $fileThermal -Expected $ExpectedHash.thermal

Start-BitsDownloadWithProgress -Url $urlRunner -Destination $fileRunnerTmp -Label "Downloading runner script"
Ensure-Hash -Path $fileRunnerTmp -Expected $ExpectedHash.runner

# Tenta encerrar processo que possa travar substituição
try {
    Get-Process | Where-Object { $_.Path -and ($_.Path -ieq $programExe) } | Stop-Process -Force -ErrorAction SilentlyContinue
} catch {}

# Move arquivos para a pasta do programa
Copy-Item -Path $fileThermal -Destination $programDir -Force
Copy-Item -Path $fileRunnerTmp -Destination $fileRunner -Force

# Limpa temporários
Remove-Item -Path $fileThermal,$fileRunnerTmp -Force -ErrorAction SilentlyContinue

# ------------------ Ícone e atalho ------------------
try {
    Start-BitsDownloadWithProgress -Url $iconUrl -Destination $iconPath -Label "Downloading app icon"
} catch {
    Write-Host "Icon download failed. Continuing without custom icon."
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $fileRunner
if (Test-Path $iconPath) { $shortcut.IconLocation = $iconPath }
$shortcut.Description = $Config.ShortcutDescription
$shortcut.Save()

# ------------------ Finalização ------------------
Write-Host ""
Write-Host "The Breeze installation has been completed successfully! Press any key to exit."
try { $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null } catch {}
try { Stop-Transcript | Out-Null } catch {}
