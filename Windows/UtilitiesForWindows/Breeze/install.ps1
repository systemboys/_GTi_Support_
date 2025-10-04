﻿# install.ps1 - Script de instalação do Breeze
# Autor: Marcos Aurélio R. da Silva <systemboys@hotmail.com>
# Versão: 2.0.0 - 2025-10-05 17h47 - Versão 2 do Script.

param(
    [string]$OrigDesktop
)

# =====================================================================
# CONFIGURAÇÕES DO SCRIPT
# =====================================================================

$Config = @{
    # URLs de download
    UrlInstaller = "https://onedrive.live.com/personal/fe54bd7ca85fc328/_layouts/15/download.aspx?UniqueId=c851b796%2D54a7%2D4850%2Db3f1%2Db16bd454ffa9"
    UrlThermal   = "https://onedrive.live.com/personal/fe54bd7ca85fc328/_layouts/15/download.aspx?UniqueId=a85fc328%2Dbd7c%2D2054%2D80fe%2Dc23702000000"
    UrlRunner    = "https://www.companyservices.com.br/gti-sis-stock-5/run_breeze.bat"
    IconUrl      = "https://github.com/systemboys/SiSFloatBase_image/raw/main/Logo/ICOs/favicon_2.0.0.ico"
    
    # Nomes dos arquivos
    FileInstallerName = "Install_Breeze.exe"
    FileThermalName   = "thermal_printing.exe"
    FileRunnerName    = "run_breeze.bat"
    IconFileName      = "favicon_2.0.0.ico"
    
    # Diretórios
    InstallDir = "$env:LOCALAPPDATA\Programs\Electron-WebView-Breeze"
    MainExe    = "$env:LOCALAPPDATA\Programs\Electron-WebView-Breeze\Breeze.exe"
    
    # Atalho
    ShortcutName = "Breeze.lnk"
    ShortcutDescription = "Executar o Breeze"
}

# =====================================================================
# FUNÇÕES AUXILIARES
# =====================================================================

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-ElevatedScript {
    param([string]$OrigDesktop)
    
    Write-Log "Script não está executando como administrador. Reexecutando com privilégios elevados..."
    
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = @(
        "-NoProfile"
        "-ExecutionPolicy Bypass"
        "-File `"$scriptPath`""
        "-OrigDesktop `"$OrigDesktop`""
    )
    
    try {
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $arguments -Wait
        exit
    } catch {
        Write-Log "ERRO: Não foi possível executar como administrador: $($_.Exception.Message)"
        Write-Host "Pressione qualquer tecla para sair..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

function Invoke-SafeDownload {
    param(
        [string]$Url,
        [string]$Destination,
        [string]$Description = "Downloading"
    )
    
    Write-Log "Iniciando download: $Description"
    Write-Log "URL: $Url"
    Write-Log "Destino: $Destination"
    
    # Garantir que o diretório de destino existe
    $destDir = Split-Path -Path $Destination -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }
    
    try {
        # Configurar TLS
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Download com progresso
        $webClient = New-Object System.Net.WebClient
        
        # Evento de progresso
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $Global:downloadProgress = $Event.SourceEventArgs.ProgressPercentage
        } | Out-Null
        
        Register-ObjectEvent -InputObject $webClient -EventName DownloadFileCompleted -Action {
            $Global:downloadCompleted = $true
        } | Out-Null
        
        $Global:downloadCompleted = $false
        $Global:downloadProgress = 0
        
        # Iniciar download
        $webClient.DownloadFileAsync([uri]$Url, $Destination)
        
        # Mostrar progresso
        while (-not $Global:downloadCompleted) {
            Write-Progress -Activity $Description -Status "$($Global:downloadProgress)% completo" -PercentComplete $Global:downloadProgress
            Start-Sleep -Milliseconds 100
        }
        
        Write-Progress -Activity $Description -Completed
        
        # Verificar se o arquivo foi baixado
        if (Test-Path $Destination) {
            $fileSize = (Get-Item $Destination).Length
            Write-Log "Download concluído com sucesso! Tamanho: $([math]::Round($fileSize/1MB, 2)) MB"
            return $true
        } else {
            throw "Arquivo não foi baixado corretamente"
        }
        
    } catch {
        Write-Log "ERRO no download: $($_.Exception.Message)"
        return $false
    } finally {
        # Limpar eventos
        if ($webClient) {
            $webClient.Dispose()
        }
        Get-EventSubscriber | Where-Object { $_.SourceObject -eq $webClient } | Unregister-Event
    }
}

function Remove-DesktopShortcuts {
    param([string]$DesktopPath)
    
    Write-Log "Removendo atalhos existentes do Breeze na área de trabalho..."
    
    try {
        # Procurar por atalhos relacionados ao Breeze
        $shortcuts = Get-ChildItem -Path $DesktopPath -Filter "*.lnk" -ErrorAction SilentlyContinue
        
        foreach ($shortcut in $shortcuts) {
            try {
                $shell = New-Object -ComObject WScript.Shell
                $link = $shell.CreateShortcut($shortcut.FullName)
                
                # Verificar se o atalho aponta para o Breeze
                if ($link.TargetPath -like "*Breeze*" -or $shortcut.Name -like "*Breeze*") {
                    Write-Log "Removendo atalho: $($shortcut.Name)"
                    Remove-Item -Path $shortcut.FullName -Force
                }
            } catch {
                Write-Log "Aviso: Não foi possível verificar/remover $($shortcut.Name)"
            }
        }
    } catch {
        Write-Log "Aviso: Erro ao remover atalhos existentes: $($_.Exception.Message)"
    }
}

function New-DesktopShortcut {
    param(
        [string]$TargetPath,
        [string]$IconPath,
        [string]$ShortcutPath,
        [string]$Description
    )
    
    Write-Log "Criando atalho na área de trabalho..."
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $TargetPath
        
        if (Test-Path $IconPath) {
            $shortcut.IconLocation = $IconPath
        }
        
        $shortcut.Description = $Description
        $shortcut.Save()
        
        Write-Log "Atalho criado com sucesso: $ShortcutPath"
        return $true
    } catch {
        Write-Log "ERRO ao criar atalho: $($_.Exception.Message)"
        return $false
    }
}

# =====================================================================
# SCRIPT PRINCIPAL
# =====================================================================

# Configurar console
try {
    Clear-Host
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "White"
} catch {}

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "    INSTALADOR DO BREEZE - v2.0.0" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar privilégios de administrador
if (-not (Test-Administrator)) {
    $desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::DesktopDirectory)
    if ([string]::IsNullOrWhiteSpace($OrigDesktop)) {
        Start-ElevatedScript -OrigDesktop $desktopPath
    } else {
        Start-ElevatedScript -OrigDesktop $OrigDesktop
    }
}

Write-Log "Script executando com privilégios de administrador"

# Definir caminhos
$tempDir = $env:TEMP
$desktopPath = if ([string]::IsNullOrWhiteSpace($OrigDesktop)) {
    [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::DesktopDirectory)
} else {
    $OrigDesktop
}

$tempFiles = @{
    Installer = Join-Path $tempDir $Config.FileInstallerName
    Thermal   = Join-Path $tempDir $Config.FileThermalName
    Runner    = Join-Path $tempDir $Config.FileRunnerName
    Icon      = Join-Path $tempDir $Config.IconFileName
}

$installFiles = @{
    Thermal = Join-Path $Config.InstallDir $Config.FileThermalName
    Runner  = Join-Path $Config.InstallDir $Config.FileRunnerName
    Icon    = Join-Path $Config.InstallDir $Config.IconFileName
}

$shortcutPath = Join-Path $desktopPath $Config.ShortcutName

Write-Log "Diretório temporário: $tempDir"
Write-Log "Diretório de instalação: $($Config.InstallDir)"
Write-Log "Área de trabalho: $desktopPath"

# =====================================================================
# DOWNLOAD DOS ARQUIVOS
# =====================================================================

Write-Log "Iniciando downloads..."

$downloads = @(
    @{ Url = $Config.UrlInstaller; Dest = $tempFiles.Installer; Desc = "Instalador do Breeze" },
    @{ Url = $Config.UrlThermal; Dest = $tempFiles.Thermal; Desc = "Componente de impressão térmica" },
    @{ Url = $Config.UrlRunner; Dest = $tempFiles.Runner; Desc = "Script de execução" },
    @{ Url = $Config.IconUrl; Dest = $tempFiles.Icon; Desc = "Ícone do aplicativo" }
)

$downloadSuccess = $true
foreach ($download in $downloads) {
    if (-not (Invoke-SafeDownload -Url $download.Url -Destination $download.Dest -Description $download.Desc)) {
        $downloadSuccess = $false
        break
    }
}

if (-not $downloadSuccess) {
    Write-Log "ERRO: Falha no download de um ou mais arquivos"
    Write-Host "Pressione qualquer tecla para sair..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Log "Todos os downloads foram concluídos com sucesso!"

# =====================================================================
# INSTALAÇÃO DO BREEZE
# =====================================================================

Write-Log "Executando instalador do Breeze..."

try {
    # Parâmetros para instalação silenciosa
    $installArgs = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-')
    
    # Executar instalador
    $process = Start-Process -FilePath $tempFiles.Installer -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    
    Write-Log "Instalador finalizado. Código de saída: $($process.ExitCode)"
    
    if ($process.ExitCode -ne 0) {
        Write-Log "AVISO: Instalador retornou código de erro $($process.ExitCode)"
    }
    
} catch {
    Write-Log "ERRO ao executar instalador: $($_.Exception.Message)"
    Write-Host "Pressione qualquer tecla para sair..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Aguardar um pouco para garantir que a instalação foi finalizada
Start-Sleep -Seconds 3

# Verificar se o Breeze foi instalado
if (-not (Test-Path $Config.MainExe)) {
    Write-Log "ERRO: Breeze não foi instalado corretamente em $($Config.MainExe)"
    Write-Host "Pressione qualquer tecla para sair..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Log "Breeze instalado com sucesso em $($Config.MainExe)"

# =====================================================================
# LIMPEZA E ORGANIZAÇÃO
# =====================================================================

# Remover atalhos existentes do Breeze na área de trabalho
Remove-DesktopShortcuts -DesktopPath $desktopPath

# Remover instalador temporário
Write-Log "Removendo instalador temporário..."
try {
    Remove-Item -Path $tempFiles.Installer -Force -ErrorAction SilentlyContinue
} catch {
    Write-Log "Aviso: Não foi possível remover o instalador temporário"
}

# Garantir que o diretório de instalação existe
if (-not (Test-Path $Config.InstallDir)) {
    Write-Log "ERRO: Diretório de instalação não encontrado: $($Config.InstallDir)"
    Write-Host "Pressione qualquer tecla para sair..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Copiar arquivos para o diretório de instalação
Write-Log "Copiando arquivos adicionais para o diretório de instalação..."

$copyFiles = @(
    @{ Source = $tempFiles.Thermal; Dest = $installFiles.Thermal },
    @{ Source = $tempFiles.Runner; Dest = $installFiles.Runner },
    @{ Source = $tempFiles.Icon; Dest = $installFiles.Icon }
)

foreach ($copy in $copyFiles) {
    try {
        Write-Log "Copiando $($copy.Source) para $($copy.Dest)"
        Copy-Item -Path $copy.Source -Destination $copy.Dest -Force
        Write-Log "Arquivo copiado com sucesso"
    } catch {
        Write-Log "ERRO ao copiar arquivo: $($_.Exception.Message)"
    }
}

# =====================================================================
# CRIAÇÃO DO ATALHO
# =====================================================================

Write-Log "Criando atalho na área de trabalho..."

$shortcutCreated = New-DesktopShortcut -TargetPath $installFiles.Runner -IconPath $installFiles.Icon -ShortcutPath $shortcutPath -Description $Config.ShortcutDescription

if (-not $shortcutCreated) {
    Write-Log "AVISO: Não foi possível criar o atalho na área de trabalho"
}

# =====================================================================
# LIMPEZA FINAL
# =====================================================================

Write-Log "Removendo arquivos temporários..."
try {
    Remove-Item -Path $tempFiles.Thermal, $tempFiles.Runner, $tempFiles.Icon -Force -ErrorAction SilentlyContinue
    Write-Log "Arquivos temporários removidos"
} catch {
    Write-Log "Aviso: Não foi possível remover alguns arquivos temporários"
}

# =====================================================================
# FINALIZAÇÃO
# =====================================================================

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "    INSTALAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "O Breeze foi instalado em: $($Config.InstallDir)" -ForegroundColor Yellow
Write-Host "Atalho criado na área de trabalho: $($Config.ShortcutName)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

