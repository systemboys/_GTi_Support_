# install_gti_sis.ps1 - Executa o script de instalação de Install GTi SiS.
#
# Autor: Marcos Aurélio R. da Silva <systemboys@hotmail.com>
# Manutenção: Marcos Aurélio R. da Silva <systemboys@hotmail.com>
#
# ---------------------------------------------------------------
# Este programa tem a finalidade de facilitar na instalação de
# pacotes para Windows.
# ---------------------------------------------------------------
# Histórico:
# v0.0.1 2024-04-14 às 02h02, Marcos Aurélio:
#   - Versão inicial, Instalação de Install GTi SiS.
#
# Licença: GPL.

# Verifica se o Windows PowerShell está sendo executado como administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script precisa ser executado como administrador."
    Start-Process powershell -Verb RunAs -ArgumentList "-Command irm https://github.com/systemboys/_GTi_Support_/raw/main/Windows/UtilitiesForWindows/install_gti_sis.ps1 | iex"
    exit
}

# Define a cor de fundo para preto
$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host  # Limpa a tela para aplicar a nova cor

# Ativar a execução de scripts no PowerShell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# Definindo URLs dos arquivos
$url1 = "https://companyservices.com.br/downloads/gti_sis_stock_install.exe"
$url2 = "https://me7yna.sn.files.1drv.com/y4mM0uZknKIhGjNs8_EMZVydcPZ_p11pVt1SZ50rBxWNgNXSqVpoFmxRnlLZY8n5X5XOII58sTWU2OsklRxlQ2BzE4mCI2gXuW84cLCADGHpccJhdqNTwSRnqeQX9K1BGbrl3Ui3s7KJeOUhJ5BL_keLWQU4LL11eLlo6t2ft8cVY2YLxJzWn_TvCWRtoRNH5VzYfFF8JQb5dP76mtTmryYPw"

# Definindo os nomes dos arquivos
$file1 = "$env:temp\gti_sis_stock_install.exe"
$file2 = "$env:temp\thermal_printing.exe"

# Baixando o primeiro arquivo
Start-BitsTransfer -Source $url1 -Destination $file1

# Executando o primeiro arquivo
Start-Process -FilePath $file1 -Wait

# Baixando o segundo arquivo
Start-BitsTransfer -Source $url2 -Destination $file2

# Verificando se o diretório do programa existe
if (Test-Path -Path "$env:SystemDrive\Program Files (x86)\GTi SiS Stock") {
    # Copiando o segundo arquivo para o diretório do programa
    Copy-Item -Path $file2 -Destination "$env:SystemDrive\Program Files (x86)\GTi SiS Stock"
    
    # Removendo os arquivos baixados
    Remove-Item -Path $file1
    Remove-Item -Path $file2
}

# Caminho do programa
$programPath = "$env:SystemDrive\Program Files (x86)\GTi SiS Stock\thermal_printing.exe"

# Caminho do Desktop
$desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::DesktopDirectory)

# Nome do atalho
$shortcutName = "GTi SiS Stock Print"

# Caminho completo para o atalho
$shortcutPath = Join-Path -Path $desktopPath -ChildPath "$shortcutName.lnk"

# URL do ícone
$iconUrl = "https://github.com/systemboys/_GTi_Support_/raw/main/icons/favicon_0.ico"

# Caminho local para salvar o ícone
$iconPath = "$env:USERPROFILE\favicon_0.ico"

# Baixar o ícone
Invoke-WebRequest -Uri $iconUrl -OutFile $iconPath

# Criar um objeto WScript.Shell
$shell = New-Object -ComObject WScript.Shell

# Criar atalho
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $programPath
$shortcut.IconLocation = $iconPath
$shortcut.Description = "Plugin for thermal printing"
$shortcut.Save()

# Exibindo a mensagem final
Write-Host "A instalação do GTi SiS foi concluída com sucesso! Pressione qualquer tecla para sair."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
