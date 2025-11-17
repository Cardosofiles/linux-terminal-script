#!/bin/bash
#=============================================================================
# 05-fzf.sh - Instalação e configuração do FZF (Fuzzy Finder)
#=============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="fzf"
readonly FZF_DIR="$HOME/.fzf"

#=============================================================================
# Funções
#=============================================================================

install_fzf() {
    if command_exists fzf; then
        local version
        version=$(fzf --version | cut -d' ' -f1)
        log_info "FZF já instalado: $version"
        mark_installed "$COMPONENT" "$version"
        return 0
    fi
    
    log_info "Instalando FZF..."
    apt_install fzf
    
    local version
    version=$(fzf --version | cut -d' ' -f1)
    mark_installed "$COMPONENT" "$version"
}

configure_fzf_zsh() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "FZF_DEFAULT_OPTS" "$zshrc" 2>/dev/null; then
        log_info "FZF já configurado no .zshrc"
        return 0
    fi
    
    log_info "Configurando FZF no Zsh..."
    
    backup_file "$zshrc"
    
    cat >> "$zshrc" << 'EOF'

# ==========================================
# FZF Configuration
# ==========================================

# Layout e visual
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --inline-info
  --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
  --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
  --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
  --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
'

# Usar fd se disponível (mais rápido)
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# Key bindings
# CTRL-T: buscar arquivos
# CTRL-R: buscar no histórico
# ALT-C: navegar diretórios

EOF
    
    mark_installed "${COMPONENT}_configured" "yes"
}

install_fzf_plugins() {
    local zshrc="$HOME/.zshrc"
    
    # Adicionar fzf nos plugins do Oh My Zsh
    if ! grep "plugins=.*fzf" "$zshrc"; then
        log_info "Adicionando fzf aos plugins..."
        sed -i 's/plugins=(\(.*\))/plugins=(\1 fzf)/' "$zshrc"
    fi
}

create_fzf_aliases() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "# FZF Aliases" "$zshrc" 2>/dev/null; then
        log_info "Aliases FZF já configurados"
        return 0
    fi
    
    log_info "Criando aliases úteis com FZF..."
    
    cat >> "$zshrc" << 'EOF'

# ==========================================
# FZF Aliases
# ==========================================

# Buscar e abrir arquivo com editor
alias fzf-edit='nano $(fzf --preview="bat --color=always {}" --preview-window=right:60%)'

# Buscar no histórico e copiar para clipboard
alias fzf-history='history | fzf | cut -c 8-'

# Buscar e cd em diretório
alias fzf-cd='cd $(fd --type d | fzf)'

# Buscar processo e matar
alias fzf-kill='ps aux | fzf | awk "{print \$2}" | xargs kill -9'

# Buscar em arquivos (requer ripgrep)
if command -v rg &> /dev/null; then
    alias fzf-search='rg --line-number --no-heading --color=always . | fzf --ansi'
fi

EOF
    
    mark_installed "${COMPONENT}_aliases" "yes"
}

show_usage_info() {
    log_info ""
    log_info "═══════════════════════════════════════════════════"
    log_success "FZF instalado com sucesso!"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    echo "Atalhos de teclado:"
    echo "  • CTRL+T     - Buscar arquivos"
    echo "  • CTRL+R     - Buscar no histórico"
    echo "  • ALT+C      - Navegar diretórios"
    echo ""
    echo "Aliases criados:"
    echo "  • fzf-edit   - Buscar e abrir arquivo"
    echo "  • fzf-cd     - Buscar e entrar em diretório"
    echo "  • fzf-kill   - Buscar e matar processo"
    echo ""
    echo "Recarregue o shell: exec zsh"
    echo ""
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section "FZF - Fuzzy Finder"
    
    install_fzf
    configure_fzf_zsh
    install_fzf_plugins
    create_fzf_aliases
    show_usage_info
    
    mark_installed "$COMPONENT" "$(fzf --version | cut -d' ' -f1)"
    
    log_success "FZF configurado"
}

main "$@"
