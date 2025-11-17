#!/bin/bash
#=============================================================================
# 11-extras.sh - Instalação de ferramentas extras úteis
#=============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="extras"

#=============================================================================
# Ferramentas para instalar
#=============================================================================

readonly EXTRA_TOOLS=(
    bat          # Cat com syntax highlighting
    fd-find      # Find moderno
    ripgrep      # Grep ultra-rápido
    tree         # Visualizar árvore de diretórios
    neofetch     # Info do sistema
    jq           # Processar JSON
    httpie       # Cliente HTTP amigável
    ncdu         # Analisador de disco
    tldr         # Man pages simplificadas
)

#=============================================================================
# Funções
#=============================================================================

install_extra_tools() {
    log_info "Instalando ferramentas extras..."
    apt_install "${EXTRA_TOOLS[@]}"
}

configure_bat_alias() {
    local bin_dir="$HOME/.local/bin"
    mkdir_safe "$bin_dir"
    
    if [[ -f "$bin_dir/bat" ]]; then
        log_info "Alias 'bat' já configurado"
        return 0
    fi
    
    log_info "Criando alias 'bat' -> 'batcat'..."
    ln_safe "$(which batcat)" "$bin_dir/bat"
    
    # Configurar tema
    local bat_config="$HOME/.config/bat/config"
    mkdir -p "$(dirname "$bat_config")"
    
    if [[ ! -f "$bat_config" ]]; then
        cat > "$bat_config" << 'EOF'
--theme="Dracula"
--style="numbers,changes,header"
--paging=auto
EOF
        log_info "Configuração do bat criada"
    fi
}

configure_fd_alias() {
    local bin_dir="$HOME/.local/bin"
    mkdir_safe "$bin_dir"
    
    if [[ -f "$bin_dir/fd" ]]; then
        log_info "Alias 'fd' já configurado"
        return 0
    fi
    
    log_info "Criando alias 'fd' -> 'fdfind'..."
    ln_safe "$(which fdfind)" "$bin_dir/fd"
}

ensure_local_bin_in_path() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q '.local/bin' "$zshrc" 2>/dev/null; then
        log_info "~/.local/bin já no PATH"
        return 0
    fi
    
    log_info "Adicionando ~/.local/bin ao PATH..."
    append_once "$zshrc" \
        'export PATH="$HOME/.local/bin:$PATH"' \
        ".local/bin"
}

install_exa() {
    if command_exists exa; then
        log_info "exa já instalado"
        mark_installed "exa" "$(exa --version | head -n1 | cut -d' ' -f2)"
        return 0
    fi
    
    log_info "Instalando exa (ls moderno)..."
    
    # exa não está no repositório padrão, instalar via cargo ou binário
    if command_exists cargo; then
        cargo install exa 2>&1 | tee -a "$LOG_FILE"
    else
        log_warning "exa requer cargo (Rust). Pulando..."
        return 0
    fi
    
    mark_installed "exa" "$(exa --version | head -n1 | cut -d' ' -f2)"
}

create_useful_aliases() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "# Useful Aliases" "$zshrc" 2>/dev/null; then
        log_info "Aliases úteis já configurados"
        return 0
    fi
    
    log_info "Criando aliases úteis..."
    
    cat >> "$zshrc" << 'EOF'

# ==========================================
# Useful Aliases
# ==========================================

# Modern replacements
alias cat='bat'
alias find='fd'
alias grep='rg'

# exa (se instalado)
if command -v exa &> /dev/null; then
    alias ls='exa --icons'
    alias ll='exa -lh --icons'
    alias la='exa -lah --icons'
    alias tree='exa --tree --icons'
fi

# System
alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean'

# Disk usage
alias du='ncdu --color dark -rr -x'
alias df='df -h'

# Network
alias ports='netstat -tulanp'
alias myip='curl -s ifconfig.me'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Productivity
alias c='clear'
alias h='history'
alias please='sudo'
alias fucking='sudo'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

EOF
    
    mark_installed "${COMPONENT}_aliases" "yes"
}

install_github_cli() {
    if command_exists gh; then
        local version
        version=$(gh --version | head -n1 | cut -d' ' -f3)
        log_info "GitHub CLI já instalado: $version"
        mark_installed "gh" "$version"
        return 0
    fi
    
    log_info "Instalando GitHub CLI (gh)..."
    
    # Adicionar repositório
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" | \
        sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    sudo apt-get update 2>&1 | tee -a "$LOG_FILE"
    apt_install gh
    
    local version
    version=$(gh --version | head -n1 | cut -d' ' -f3)
    mark_installed "gh" "$version"
    log_success "GitHub CLI instalado: $version"
}

show_extras_info() {
    log_info ""
    log_info "═══════════════════════════════════════════════════"
    log_success "Ferramentas extras instaladas!"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    echo "Ferramentas disponíveis:"
    echo "  • bat           - Cat com syntax highlighting"
    echo "  • fd            - Find moderno"
    echo "  • rg (ripgrep)  - Grep ultra-rápido"
    echo "  • tree          - Árvore de diretórios"
    echo "  • neofetch      - Info do sistema"
    echo "  • jq            - Processar JSON"
    echo "  • httpie        - Cliente HTTP"
    echo "  • ncdu          - Analisador de disco"
    echo "  • gh            - GitHub CLI"
    echo ""
    echo "Experimente:"
    echo "  • bat arquivo.txt"
    echo "  • fd pattern"
    echo "  • rg 'search term'"
    echo "  • neofetch"
    echo "  • gh repo list"
    echo ""
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section "Ferramentas Extras"
    
    install_extra_tools
    configure_bat_alias
    configure_fd_alias
    ensure_local_bin_in_path
    install_exa
    create_useful_aliases
    install_github_cli
    show_extras_info
    
    mark_installed "$COMPONENT" "installed"
    
    log_success "Ferramentas extras configuradas"
}

main "$@"
