#!/bin/bash
#=============================================================================
# 01-system.sh - Atualização e configuração base do sistema Ubuntu
#=============================================================================

set -euo pipefail

# Carregar bibliotecas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="system"

#=============================================================================
# Pacotes Essenciais
#=============================================================================

readonly ESSENTIAL_PACKAGES=(
    # Build essentials
    build-essential
    
    # Ferramentas de rede
    curl
    wget
    ca-certificates
    gnupg
    lsb-release
    
    # Utilitários
    git
    unzip
    zip
    tar
    
    # Ferramentas de desenvolvimento
    software-properties-common
    apt-transport-https
    
    # Ferramentas de sistema
    htop
    tree
    nano
    vim
    
    # Bibliotecas comuns
    libssl-dev
    libffi-dev
    libreadline-dev
    zlib1g-dev
    libbz2-dev
    libsqlite3-dev
    
    # Python build dependencies
    python3-pip
    python3-dev
)

#=============================================================================
# Funções
#=============================================================================

update_system() {
    log_info "Atualizando cache de pacotes..."
    sudo apt-get update 2>&1 | tee -a "$LOG_FILE"
    
    if is_installed "${COMPONENT}_updated"; then
        log_info "Sistema já atualizado nesta sessão"
        return 0
    fi
    
    log_info "Atualizando pacotes instalados..."
    sudo apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"
    
    mark_installed "${COMPONENT}_updated" "$(date +%Y%m%d)"
}

install_essentials() {
    log_info "Instalando pacotes essenciais..."
    apt_install "${ESSENTIAL_PACKAGES[@]}"
}

configure_locale() {
    if is_installed "${COMPONENT}_locale"; then
        log_info "Locale já configurado"
        return 0
    fi
    
    log_info "Configurando locale..."
    
    sudo locale-gen pt_BR.UTF-8
    sudo locale-gen en_US.UTF-8
    sudo update-locale LANG=pt_BR.UTF-8 LC_ALL=pt_BR.UTF-8
    
    mark_installed "${COMPONENT}_locale" "pt_BR.UTF-8"
}

configure_timezone() {
    if is_installed "${COMPONENT}_timezone"; then
        log_info "Timezone já configurado"
        return 0
    fi
    
    log_info "Configurando timezone para America/Sao_Paulo..."
    sudo timedatectl set-timezone America/Sao_Paulo 2>/dev/null || {
        sudo ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    }
    
    mark_installed "${COMPONENT}_timezone" "America/Sao_Paulo"
}

configure_systemd() {
    local wsl_conf="/etc/wsl.conf"
    
    if grep -q "systemd=true" "$wsl_conf" 2>/dev/null; then
        log_info "systemd já habilitado"
        return 0
    fi
    
    log_info "Habilitando systemd no WSL..."
    
    backup_file "$wsl_conf"
    
    sudo tee "$wsl_conf" > /dev/null << 'EOF'
[boot]
systemd=true

[automount]
enabled=true
mountFsTab=true

[interop]
enabled=true
appendWindowsPath=true

[network]
generateHosts=true
generateResolvConf=true
EOF
    
    log_warning "systemd habilitado. Reinicie o WSL para aplicar:"
    log_warning "  No PowerShell: wsl --shutdown"
    
    mark_installed "${COMPONENT}_systemd" "enabled"
}

optimize_apt() {
    local apt_conf="/etc/apt/apt.conf.d/99custom"
    
    if is_installed "${COMPONENT}_apt_optimized"; then
        log_info "APT já otimizado"
        return 0
    fi
    
    log_info "Otimizando configurações APT..."
    
    sudo tee "$apt_conf" > /dev/null << 'EOF'
# Otimizações APT para WSL
Acquire::http::Timeout "5";
Acquire::https::Timeout "5";
Acquire::ftp::Timeout "5";
Acquire::Retries "3";

# Cache
Dir::Cache::Archives "archives";
APT::Clean-Installed "true";

# Performance
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF
    
    echo "rm -f $apt_conf" >> "$ROLLBACK_LOG"
    
    mark_installed "${COMPONENT}_apt_optimized" "yes"
}

cleanup_system() {
    log_info "Limpando pacotes desnecessários..."
    
    sudo apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"
    sudo apt-get autoclean 2>&1 | tee -a "$LOG_FILE"
    
    log_success "Sistema limpo"
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section "Sistema Base Ubuntu"
    
    update_system
    install_essentials
    configure_locale
    configure_timezone
    configure_systemd
    optimize_apt
    cleanup_system
    
    mark_installed "$COMPONENT" "$(lsb_release -rs)"
    
    log_success "Sistema base configurado com sucesso"
}

main "$@"
