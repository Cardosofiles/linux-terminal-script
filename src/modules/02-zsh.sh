#!/bin/bash
#=============================================================================
# 02-zsh.sh - Instalação e configuração do Zsh + Oh My Zsh
#=============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="zsh"
readonly OH_MY_ZSH_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
readonly ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

#=============================================================================
# Funções
#=============================================================================

install_zsh() {
    if command_exists zsh; then
        local version
        version=$(zsh --version | cut -d' ' -f2)
        log_info "Zsh já instalado: $version"
        mark_installed "${COMPONENT}_binary" "$version"
        return 0
    fi
    
    log_info "Instalando Zsh..."
    apt_install zsh
    
    local version
    version=$(zsh --version | cut -d' ' -f2)
    mark_installed "${COMPONENT}_binary" "$version"
}

install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh já instalado"
        mark_installed "oh-my-zsh" "$(cd ~/.oh-my-zsh && git describe --tags)"
        return 0
    fi
    
    log_info "Instalando Oh My Zsh..."
    
    # Baixar e instalar de forma não-interativa
    export RUNZSH=no
    export CHSH=no
    
    sh -c "$(curl -fsSL $OH_MY_ZSH_URL)" "" --unattended 2>&1 | tee -a "$LOG_FILE"
    
    # Registrar para rollback
    echo "rm -rf $HOME/.oh-my-zsh" >> "$ROLLBACK_LOG"
    
    mark_installed "oh-my-zsh" "$(cd ~/.oh-my-zsh && git describe --tags)"
    log_success "Oh My Zsh instalado"
}

configure_zshrc() {
    local zshrc="$HOME/.zshrc"
    
    if is_installed "${COMPONENT}_zshrc_configured"; then
        log_info ".zshrc já configurado"
        return 0
    fi
    
    log_info "Configurando .zshrc base..."
    
    # Backup do .zshrc existente
    if [[ -f "$zshrc" ]]; then
        backup_file "$zshrc"
    fi
    
    # Usar template se existir, senão criar básico
    if [[ -f "$SCRIPT_DIR/config/templates/.zshrc.template" ]]; then
        cp "$SCRIPT_DIR/config/templates/.zshrc.template" "$zshrc"
    else
        # Configuração básica
        cat > "$zshrc" << 'EOF'
# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme (será configurado pelo módulo powerlevel10k)
ZSH_THEME="robbyrussell"

# Plugins (será expandido pelo módulo de plugins)
plugins=(git)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=pt_BR.UTF-8
export EDITOR='nano'

# History
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS

# Aliases básicos
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
EOF
    fi
    
    mark_installed "${COMPONENT}_zshrc_configured" "yes"
}

set_default_shell() {
    local current_shell
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    local zsh_path
    zsh_path="$(which zsh)"
    
    if [[ "$current_shell" == "$zsh_path" ]]; then
        log_info "Zsh já é o shell padrão"
        return 0
    fi
    
    log_info "Definindo Zsh como shell padrão..."
    change_shell_safe "$zsh_path"
    
    log_warning "Para ativar o Zsh, execute: exec zsh"
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section "Zsh + Oh My Zsh"
    
    install_zsh
    install_oh_my_zsh
    configure_zshrc
    set_default_shell
    
    mark_installed "$COMPONENT" "$(zsh --version | cut -d' ' -f2)"
    
    log_success "Zsh configurado com sucesso"
}

main "$@"
