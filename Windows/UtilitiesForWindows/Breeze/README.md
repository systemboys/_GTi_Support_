# Breeze - Script de Instalação Automatizada

## Instalação Rápida via PowerShell

O arquivo `install.ps1` está hospedado em um servidor e disponível para download e execução automática através do Windows PowerShell.

### Como instalar

**Abra o Windows PowerShell como Administrador** e execute o seguinte comando:

```powershell
irm install-breeze.systemboys.com.br | iex
```

Este comando irá baixar e executar automaticamente o script de instalação do Breeze.

---

## O que o Script de Instalação Faz

O script `install.ps1` realiza uma instalação completa e automatizada do sistema Breeze, executando as seguintes operações:

### Funcionalidades Principais:

- ✅ **Verificação de Privilégios de Administrador**
  - Detecta se o PowerShell está sendo executado com privilégios administrativos
  - Auto-eleva as permissões caso necessário, solicitando confirmação do usuário

- 📁 **Criação de Diretório Temporário**
  - Cria um diretório temporário em `%TEMP%\Install_Breeze` para armazenar os arquivos de instalação
  - Remove diretórios temporários existentes para garantir uma instalação limpa

- 📥 **Download de Componentes Necessários**
  - `Install_Breeze.exe` - Instalador principal do aplicativo Breeze
  - `thermal_printing.exe` - Módulo de impressão térmica
  - `run_breeze.bat` - Script em lote para execução do sistema
  - `favicon_2.0.0.ico` - Ícone personalizado do aplicativo

- 🔧 **Instalação Silenciosa**
  - Executa o instalador principal (`Install_Breeze.exe`) em modo silencioso (`/S`)
  - Instala o aplicativo em `%LOCALAPPDATA%\Programs\Electron-WebView-Breeze`
  - Aguarda a conclusão do processo de instalação

- 📋 **Cópia de Arquivos Adicionais**
  - Move os arquivos baixados (módulo de impressão, script runner e ícone) para o diretório de instalação
  - Garante que todos os componentes estejam disponíveis no local correto

- 🖥️ **Criação de Atalho na Área de Trabalho**
  - Remove atalhos antigos do Breeze (caso existam)
  - Cria um novo atalho na área de trabalho chamado "Breeze.lnk"
  - Configura o atalho para executar o arquivo `run_breeze.bat`
  - Aplica o ícone personalizado ao atalho

- 🧹 **Limpeza de Arquivos Temporários**
  - Remove completamente o diretório temporário e todos os arquivos de instalação
  - Mantém o sistema limpo após a instalação

- 📊 **Feedback Visual Durante a Instalação**
  - Exibe barra de progresso com porcentagem de conclusão
  - Mostra mensagens informativas sobre cada etapa do processo
  - Indica sucesso ou erro em cada operação realizada

---

## Sobre o Arquivo `run_breeze.bat`

O arquivo `run_breeze.bat` é um script em lote (batch) que funciona como um launcher do sistema Breeze. Quando o usuário clica no atalho criado na área de trabalho, este script é executado e realiza as seguintes ações:

1. **Inicia o aplicativo principal Breeze** (`Breeze.exe`)
2. **Executa o módulo de impressão térmica** (`thermal_printing.exe`)

Este script garante que tanto o aplicativo principal quanto o plugin de impressão térmica sejam iniciados simultaneamente, proporcionando uma experiência completa ao usuário final.

---

## Requisitos do Sistema

- **Sistema Operacional:** Windows 10 ou superior
- **Privilégios:** Permissões de administrador
- **Conectividade:** Conexão com a internet para download dos componentes

---

## Observações Importantes

- O script requer privilégios de administrador para realizar a instalação
- Todos os arquivos temporários são automaticamente removidos após a instalação
- O atalho criado na área de trabalho utiliza um ícone personalizado
- A instalação é realizada de forma silenciosa, sem intervenção do usuário

---

<div align="center">

**Desenvolvido por:**

**Marcos Aurélio Rocha da Silva**  
*Engenheiro de Software*

</div>

