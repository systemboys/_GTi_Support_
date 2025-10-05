# download_and_install.ps1 - Script simples para baixar e executar o instalador
# Execute este script primeiro para baixar o instalador principal

param(
    [string]$OrigDesktop
)

# Verificar se está executando como administrador
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Função para reexecutar como administrador
function Start-ElevatedScript {
    param([string]$OrigDesktop)
    
    Write-Host "Script não está executando como administrador. Reexecutando com privilégios elevados..." -ForegroundColor Yellow
    
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
        Write-Host "ERRO: Não foi possível executar como administrador: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Pressione qualquer tecla para sair..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# Verificar privilégios de administrador
if (-not (Test-Administrator)) {
    $desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::DesktopDirectory)
    if ([string]::IsNullOrWhiteSpace($OrigDesktop)) {
        Start-ElevatedScript -OrigDesktop $desktopPath
    } else {
        Start-ElevatedScript -OrigDesktop $OrigDesktop
    }
}

# Configurar console
Clear-Host
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "    DOWNLOAD E INSTALAÇÃO DO BREEZE" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# URLs e arquivos
$scriptUrl = "https://github.com/systemboys/_GTi_Support_/raw/refs/heads/main/Windows/UtilitiesForWindows/Breeze/install.ps1"
$tempDir = $env:TEMP
$localScript = Join-Path $tempDir "install_breeze.ps1"

Write-Host "Baixando script de instalação..." -ForegroundColor Yellow

try {
    # Configurar TLS
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Baixar script
    Invoke-WebRequest -Uri $scriptUrl -OutFile $localScript -UseBasicParsing
    
    Write-Host "Script baixado com sucesso!" -ForegroundColor Green
    Write-Host "Executando instalador..." -ForegroundColor Yellow
    Write-Host ""
    
    # Executar script local
    & $localScript
    
} catch {
    Write-Host "ERRO ao baixar o script: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Pressione qualquer tecla para sair..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
