<div align="center" id="top">

# 🚀 Sistema de Instalação Automatizada - WSL 2 + Ubuntu

> **Instalação idempotente, com rollback automático e snapshots para ambiente Full Stack**

[![Version](https://img.shields.io/badge/Version-1.0.1-blue?style=for-the-badge)](CHANGELOG.md)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-success?style=for-the-badge)](TESTING.md)
[![Ambiente de Desenvolvimento](https://img.shields.io/badge/Ambiente-Desenvolvimento-6C63FF?style=for-the-badge)](#features)
[![Idempotente](https://img.shields.io/badge/Idempotente-100%25-success?style=for-the-badge)](#arquitetura)
[![Rollback](https://img.shields.io/badge/Rollback-Automático-orange?style=for-the-badge)](#sistema-de-rollback)
[![WSL](https://img.shields.io/badge/WSL-2.0+-0078D4?style=for-the-badge&logo=windows&logoColor=white)](https://learn.microsoft.com/windows/wsl/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04+-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/wsl)
[![Node.js](https://img.shields.io/badge/Node.js-fnm-339933?style=for-the-badge&logo=node.js&logoColor=white)](#nodejs)
[![Java](https://img.shields.io/badge/Java-SDKMAN-007396?style=for-the-badge&logo=openjdk&logoColor=white)](#java)
[![PHP](https://img.shields.io/badge/PHP-8.3-777BB4?style=for-the-badge&logo=php&logoColor=white)](#php)
[![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?style=for-the-badge&logo=.net&logoColor=white)](#dotnet)
[![Docker](https://img.shields.io/badge/Docker-Integrated-2496ED?style=for-the-badge&logo=docker&logoColor=white)](#docker)
[![Zsh](https://img.shields.io/badge/Zsh-Powerlevel10k-FFD700?style=for-the-badge)](#terminal)

[![My Skills](https://skillicons.dev/icons?i=linux,ubuntu,python,java,maven,gradle,nodejs,npm,pnpm,cs,dotnet,php,docker,git,github&theme=dark)](https://skillicons.dev)

Sistema enterprise-grade com instalação modular, snapshots WSL, rollback completo e logging estruturado. Execute quantas vezes quiser - 100% idempotente e seguro.

</div>

---

## 📋 Índice

- [Features](#features)
- [Pré-requisitos](#pré-requisitos)
- [Quick Start](#quick-start)
- [Instalação Detalhada](#instalação-detalhada)
- [Modos de Instalação](#modos-de-instalação)
- [Componentes](#componentes)
- [Sistema de Snapshots](#sistema-de-snapshots)
- [Sistema de Rollback](#sistema-de-rollback)
- [Personalização](#personalização)
- [Comandos Úteis](#comandos-úteis)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Arquitetura](#arquitetura)
- [Contribuindo](#contribuindo)

---

<h2 id="features">✨ Features</h2>

### 🔧 Sistema Core

- ✅ **100% Idempotente** - Execute múltiplas vezes sem efeitos colaterais
- ✅ **Rollback Automático** - Desfaça instalações com um comando
- ✅ **Snapshots WSL** - Backup completo da distribuição
- ✅ **Logging Estruturado** - Rastreamento completo de todas as operações
- ✅ **Estado Persistente** - Sabe exatamente o que está instalado
- ✅ **Backup Automático** - Arquivos modificados são salvos antes de alterações

> 🎉 **Versão 1.0.1** - Bug crítico de variável readonly corrigido! [Ver detalhes](CHANGELOG.md)

### 🖥️ Terminal & Shell

- ✅ **Zsh** - Shell moderno e poderoso
- ✅ **Oh My Zsh** - Framework para gerenciar configurações Zsh
- ✅ **Powerlevel10k** - Tema rápido e bonito
- ✅ **Plugins** - autosuggestions, syntax-highlighting, autocomplete
- ✅ **FZF** - Busca fuzzy interativa

### 💻 Linguagens & Runtimes

- ✅ **Node.js** - Via fnm (Fast Node Manager) + pnpm
- ✅ **Java** - Via SDKMAN! (JDK + Maven + Gradle)
- ✅ **PHP 8.3** - Com Composer e extensões
- ✅ **.NET 8.0** - SDK completo + ferramentas
- ✅ **Python** - (opcional via pyenv)

### 🐳 DevOps & Tools

- ✅ **Docker** - Integração WSL + Docker Desktop
- ✅ **Git** - Configuração otimizada
- ✅ **GitHub CLI** - Ferramenta oficial do GitHub
- ✅ **Ferramentas Modernas** - bat, fd, ripgrep, exa, jq, httpie

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="pré-requisitos">Pré-requisitos</h2>

### Hardware Recomendado

| Componente   | Mínimo      | Recomendado  | Ideal       |
| ------------ | ----------- | ------------ | ----------- |
| **RAM**      | 8 GB        | 16 GB        | 32 GB+      |
| **CPU**      | 4 cores     | 6 cores      | 8+ cores    |
| **Disco**    | 50 GB livre | 100 GB livre | 256 GB+ SSD |
| **Internet** | 10 Mbps     | 50 Mbps      | 100+ Mbps   |

### Software Necessário

#### No Windows

- ✅ **Windows 10/11** (Build 19041 ou superior)
- ✅ **WSL 2** instalado e configurado
- ✅ **Windows Terminal** (recomendado)
- ✅ **Nerd Font** instalada (MesloLGS NF ou JetBrainsMono)

#### Verificação Rápida

```powershell
# No PowerShell (Windows)
# Verificar versão WSL
wsl --version

# Listar distribuições
wsl -l -v

# Versão do Windows
winver
```

### Instalar WSL 2 (Se necessário)

```powershell
# PowerShell como Administrador
wsl --install -d Ubuntu

# Reiniciar o computador
# Após reiniciar, configurar usuário no Ubuntu
```

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="quick-start">🚀 Quick Start</h2>

📝 Resumo do fluxo para executar localmente
É recomendável criar um diretório próprio para ferramentas dentro do seu home. Assim você mantém as ferramentas e scripts de automação organizados e prontos para uso. Siga o roteiro para garantir uma instalação limpa e performática.

### 1. Clone o Repositório

```bash
mkdir -p ~/bin
cd ~/bin
git clone https://github.com/Cardosofiles/linux-terminal-script.git
cd linux-terminal-script
```

### 2. Dar Permissões de Execução

```bash
chmod +x src/install.sh
chmod +x src/lib/*.sh
chmod +x src/modules/*.sh
chmod +x src/snapshots/*.sh

find src/ -type f -name "*.sh" -exec chmod +x {} \;
```

### 2.1 Adicionar ao PATH

```bash
echo 'export PATH="$HOME/bin/linux-terminal-settings/src:$PATH"' >> ~/.zshrc
source ~/.zshrc

```

### 3. Executar Instalação

```bash
# Instalação completa (recomendado)
./src/install.sh --full

# OU instalação mínima
./src/install.sh --minimal

# OU modo interativo
./src/install.sh --components
```

### 4. Recarregar Shell

```bash
exec zsh
source ~/.zshrc
```

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="instalação-detalhada">📦 Instalação Detalhada</h2>

### Passo 1: Preparação

```bash
# Acessar Ubuntu no WSL
wsl -d Ubuntu

# Atualizar sistema (opcional)
sudo apt update && sudo apt upgrade -y

# Navegar para diretório home
cd ~
```

### Passo 2: Clone e Verificação

```bash
# Clonar repositório
git clone https://github.com/Cardosofiles/linux-terminal-settings.git
cd linux-terminal-settings

# Verificar estrutura
tree -L 2 src/
```

### Passo 3: Dar Permissões

```bash
# Permissões recursivas
find src/ -type f -name "*.sh" -exec chmod +x {} \;

# Verificar
ls -lah src/install.sh
```

### Passo 4: Criar Snapshot Pré-Instalação

```bash
# Backup antes de instalar
./src/snapshots/create-snapshot.sh
```

### Passo 5: Executar Instalação

```bash
# Instalação full
./src/install.sh --full

# Tempo estimado: 15-30 minutos
```

### Passo 6: Pós-Instalação

```bash
# Recarregar shell
exec zsh

# Verificar instalação
./src/install.sh --list

# Testar componentes
node -v
java -version
php -v
dotnet --version
docker --version
```

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="modos-de-instalação">🎨 Modos de Instalação</h2>

### Modo Full (--full)

```bash
./src/install.sh --full
```

**Instala todos os 11 componentes:** Sistema base, Zsh, Powerlevel10k, Plugins, FZF, Node.js, Java, PHP, .NET, Docker, Extras

### Modo Minimal (--minimal)

```bash
./src/install.sh --minimal
```

**Instala essencial:** Sistema base, Zsh, Oh My Zsh, Powerlevel10k, Plugins, FZF

### Modo Interativo (--components)

```bash
./src/install.sh --components
```

**Escolher componentes manualmente** com menu interativo

### Modo Sem Snapshot (--skip-snapshot)

```bash
./src/install.sh --full --skip-snapshot
```

**Pula criação de snapshot** - mais rápido mas sem backup completo

### Modo Rollback (--rollback)

```bash
./src/install.sh --rollback
```

**Menu interativo para reverter instalações** - total ou parcial

### Modo Listagem (--list)

```bash
./src/install.sh --list
```

**Lista componentes instalados com versões**

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="componentes">📦 Componentes</h2>

### 01 - Sistema Base

- Pacotes essenciais, Python 3, Git
- Locale (pt_BR.UTF-8), Timezone, systemd
- Otimizações APT

```bash
./src/modules/01-system.sh
```

### 02 - Zsh + Oh My Zsh

- Zsh shell, Oh My Zsh framework
- .zshrc base configurado

```bash
./src/modules/02-zsh.sh
```

### 03 - Powerlevel10k

- Tema Powerlevel10k, instant prompt
- **Requer Nerd Font instalada no Windows**

```bash
./src/modules/03-powerlevel10k.sh
```

**Nerd Fonts recomendadas:**

- MesloLGS NF (recomendada)
- JetBrainsMono Nerd Font
- Download: https://www.nerdfonts.com/font-downloads

### 04 - Plugins Zsh

- zsh-autosuggestions, syntax-highlighting, autocomplete
- autojump (navegação rápida)

```bash
./src/modules/04-plugins.sh
```

### 05 - FZF (Fuzzy Finder)

- Busca fuzzy interativa
- Atalhos: CTRL+T (arquivos), CTRL+R (histórico), ALT+C (diretórios)

```bash
./src/modules/05-fzf.sh
```

### 06 - Node.js + pnpm

- fnm (Fast Node Manager), Node.js LTS
- pnpm via Corepack

```bash
./src/modules/06-nodejs.sh

# Gerenciar versões
fnm list-remote
fnm install 20
fnm default 20
```

### 07 - Java + Maven + Gradle

- SDKMAN!, Java JDK (Temurin 21)
- Apache Maven, Gradle

```bash
./src/modules/07-java.sh

# Gerenciar versões
sdk list java
sdk install java 17.0.9-tem
sdk default java 21.0.5-tem
```

### 08 - PHP + Composer

- PHP 8.3 CLI com extensões
- Composer, PHPUnit, PHP CS Fixer

```bash
./src/modules/08-php.sh

# Verificar extensões
php -m
```

### 09 - .NET SDK

- .NET SDK 8.0, Entity Framework
- dotnet-format, Code Generator

```bash
./src/modules/09-dotnet.sh

# Criar projeto
dotnet new console -n MeuApp
dotnet run
```

### 10 - Docker

- Docker Desktop integration ou CLI
- docker-compose, aliases úteis

```bash
./src/modules/10-docker.sh

# Testar
docker run hello-world
```

### 11 - Ferramentas Extras

- bat, fd, ripgrep, tree, neofetch, jq, httpie
- exa, GitHub CLI

```bash
./src/modules/11-extras.sh
```

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="sistema-de-snapshots">📸 Sistema de Snapshots</h2>

### Criar Snapshot

```bash
./src/snapshots/create-snapshot.sh

# Onde salva: C:\WSL-Snapshots\
# Nome: Ubuntu-snapshot-YYYYMMDD-HHMMSS.tar
```

### Listar Snapshots

```bash
./src/snapshots/list-snapshots.sh
```

### Restaurar Snapshot

```bash
./src/snapshots/restore-snapshot.sh

# Escolher snapshot → Nome da nova distribuição
# Usar: wsl -d Ubuntu-Restored
```

### Comandos WSL (PowerShell)

```powershell
# Exportar
wsl --export Ubuntu C:\Backups\ubuntu.tar

# Importar
wsl --import Ubuntu-New C:\WSL\Ubuntu-New C:\Backups\ubuntu.tar

# Listar
wsl -l -v

# Definir padrão
wsl --set-default Ubuntu-New

# Remover
wsl --unregister Ubuntu-Old
```

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="sistema-de-rollback">🔄 Sistema de Rollback</h2>

### Rollback Completo

```bash
./src/install.sh --rollback

# Menu interativo → Opção 1
```

**Remove todos os componentes instalados**

### Rollback Parcial (Componente Específico)

```bash
./src/install.sh --rollback

# Menu interativo → Opção 2 → Digite nome do componente
```

### Rollback Manual

```bash
source src/lib/rollback.sh

# Listar componentes
list_installed_components

# Rollback específico
rollback_component "nodejs"

# Restaurar backups
restore_backups
```

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="personalização">⚙️ Personalização</h2>

### Arquivo de Configuração

```bash
nano src/config/install.conf

# Opções:
INSTALL_MODE=interactive          # full | minimal | interactive
AUTO_SNAPSHOT=true                # Criar snapshot automaticamente
NODE_VERSION=lts-latest           # Versão do Node
JAVA_VERSION=21.0.5-tem           # Versão do Java
PHP_VERSION=8.3                   # Versão do PHP
DOTNET_VERSION=8.0                # Versão do .NET
ZSH_THEME=powerlevel10k           # Tema (ou starship)
GIT_USER_NAME="Seu Nome"          # Git config
GIT_USER_EMAIL="seu@email.com"    # Git config
```

### Templates de Configuração

```bash
# .zshrc template
nano src/config/templates/.zshrc.template

# Git config template
nano src/config/templates/gitconfig.template

# WSL config template
nano src/config/templates/wslconfig.template
```

### Aplicar .wslconfig no Windows

```powershell
# Editar
notepad $env:USERPROFILE\.wslconfig

# Adicionar:
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true

# Reiniciar
wsl --shutdown
```

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="comandos-úteis">🛠️ Comandos Úteis</h2>

### Gerenciamento

```bash
./src/install.sh --list                    # Listar componentes
./src/modules/06-nodejs.sh                 # Reinstalar Node.js
tail -f ~/.wsl-setup/logs/install-*.log    # Ver logs
ls -lah ~/.wsl-setup/state/                # Ver estado
```

### Snapshots

```bash
./src/snapshots/create-snapshot.sh         # Criar snapshot
./src/snapshots/list-snapshots.sh          # Listar
./src/snapshots/restore-snapshot.sh        # Restaurar
```

### Limpeza

```bash
sudo apt autoremove -y                     # Remover pacotes
sudo apt autoclean                         # Limpar cache APT
docker system prune -af --volumes          # Limpar Docker
find ~/.wsl-setup/logs -mtime +30 -delete  # Limpar logs antigos
```

### Atualização

```bash
# Node.js
fnm install --lts
fnm default lts-latest

# Java
sdk upgrade java

# PHP/Composer
sudo apt update && sudo apt upgrade
composer self-update

# .NET
sudo apt update && sudo apt upgrade dotnet-sdk-8.0

# Sistema
sudo apt update && sudo apt upgrade -y
```

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="troubleshooting">🚨 Troubleshooting</h2>

### Script sem permissão

**Erro:** `-bash: ./src/install.sh: Permission denied`

**Solução:**

```bash
chmod +x src/install.sh
# OU
bash src/install.sh --full
```

### Powerlevel10k sem ícones

**Sintoma:** Caracteres quebrados, quadrados ou �

**Solução:**

1. Download Nerd Font: https://www.nerdfonts.com/font-downloads
2. Instalar MesloLGS NF no Windows
3. Windows Terminal → Settings → Ubuntu → Appearance → Font face
4. Selecionar MesloLGS NF
5. Reconfigurar: `p10k configure`

### Docker não funciona

**Erro:** `Cannot connect to the Docker daemon`

**Soluções:**

```bash
# 1. Verificar Docker Desktop (Windows)

# 2. Habilitar WSL Integration
# Docker Desktop → Settings → Resources → WSL Integration → Ubuntu

# 3. Adicionar ao grupo docker
sudo usermod -aG docker $USER
newgrp docker

# 4. Testar
docker ps
docker run hello-world
```

### fnm: command not found

**Solução:**

```bash
# Verificar .zshrc
grep "fnm env" ~/.zshrc

# Se não estiver, adicionar
echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc

# Recarregar
exec zsh
```

### SDKMAN não encontrado

**Solução:**

```bash
# Reinstalar
./src/modules/07-java.sh

# Carregar no shell
source ~/.sdkman/bin/sdkman-init.sh

# Verificar
sdk version
```

### Instalação falha no meio

**Solução:**

```bash
# Ver erro
tail -n 50 ~/.wsl-setup/logs/install-*.log

# Reinstalar componente específico
./src/modules/XX-componente.sh

# OU continuar (sistema é idempotente)
./src/install.sh --full
```

### WSL muito lento

**Soluções:**

1. Mover projetos para filesystem Linux (~/projetos, não /mnt/c/)
2. Configurar .wslconfig (memory, processors)
3. Excluir WSL do antivírus
4. Usar `fd` em vez de `find`

### "System has not been booted with systemd"

**Solução:**

```bash
sudo nano /etc/wsl.conf

# Adicionar:
[boot]
systemd=true

# Salvar (Ctrl+X, Y, Enter)

wsl --shutdown
```

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="faq">❓ FAQ</h2>

### Posso executar múltiplas vezes?

**Sim!** Sistema é 100% idempotente - componentes já instalados serão pulados.

### Como atualizar ferramentas?

```bash
fnm install --lts             # Node.js
sdk upgrade java              # Java
sudo apt update && apt upgrade # Sistema geral
composer self-update           # Composer
```

### Posso instalar apenas alguns componentes?

```bash
./src/install.sh --components
# OU
COMPONENTS="nodejs java docker" ./src/install.sh
```

### Como adicionar minha ferramenta?

1. Criar módulo em `src/modules/12-minha-ferramenta.sh`
2. Seguir template dos módulos existentes
3. Adicionar no array de componentes do `install.sh`

### Preciso de Docker Desktop?

Não obrigatório, mas recomendado - melhor integração e performance. Alternativa: instalar só Docker CLI.

### Como funciona o rollback?

Durante instalação, ações são registradas. Rollback executa comandos de remoção em ordem reversa e restaura backups.

### Snapshots ocupam muito espaço?

Sim, 2-5 GB por snapshot. **Recomendação:** Limpe antes de criar, mantenha apenas importantes, delete antigos regularmente.

### Posso usar em produção?

Sistema é para **desenvolvimento local**, não servidores. Para produção: use Ansible, Docker, Terraform, ou CI/CD específicos.

### Preciso de Nerd Font?

Sim, se usar Powerlevel10k. **Alternativa:** Use tema Starship (mais simples).

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="arquitetura">🏗️ Arquitetura</h2>

### Estrutura de Diretórios

```
src/
├── install.sh                   # Orquestrador
├── lib/
│   ├── core.sh                 # Funções essenciais
│   ├── idempotent.sh           # Wrappers idempotentes
│   └── rollback.sh             # Reversão
├── modules/
│   ├── 01-system.sh
│   ├── 02-zsh.sh
│   ├── 03-powerlevel10k.sh
│   ├── 04-plugins.sh
│   ├── 05-fzf.sh
│   ├── 06-nodejs.sh
│   ├── 07-java.sh
│   ├── 08-php.sh
│   ├── 09-dotnet.sh
│   ├── 10-docker.sh
│   └── 11-extras.sh
├── config/
│   ├── install.conf
│   └── templates/
│       ├── .zshrc.template
│       ├── .p10k.zsh.template
│       ├── gitconfig.template
│       └── wslconfig.template
└── snapshots/
    ├── create-snapshot.sh
    ├── restore-snapshot.sh
    └── list-snapshots.sh
```

### Princípios de Design

- **Idempotência:** Cada módulo verifica estado antes de executar
- **Modularidade:** Componentes independentes, executáveis individualmente
- **Observabilidade:** Logs estruturados com timestamp, output colorido
- **Reversibilidade:** Cada ação registra como desfazer, backups automáticos
- **Atomicidade:** Cada módulo é unidade atômica

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>

---

<h2 id="contribuindo">🤝 Contribuindo</h2>

Contribuições bem-vindas! Por favor:

1. Fork o projeto
2. Crie branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

**Diretrizes:**

- ✅ Mantenha idempotência
- ✅ Adicione logs adequados
- ✅ Documente novas features
- ✅ Teste em instalação limpa
- ✅ Siga padrão de código

---

<h2 id="licença">📄 Licença</h2>

MIT License - veja LICENSE para detalhes

---

**Desenvolvido com ❤️ para a comunidade WSL**

Para dúvidas, abra uma issue no GitHub ou entre em contato!

<div align="right">

[⬆️ Voltar ao topo](#top)

</div>
