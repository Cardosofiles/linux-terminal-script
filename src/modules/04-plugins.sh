#!/bin/bash
#=============================================================================
# 04-plugins.sh - Instalação de plugins do Zsh
#=============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="plugins"
readonly ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

#=============================================================================
# Plugins a Instalar
#=============================================================================

declare -A PLUGINS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
    ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search"
)

#=============================================================================
# Funções
#=============================================================================

check_prerequisites() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_error "Oh My Zsh não instalado. Execute: modules/02-zsh.sh"
        exit 1
    fi
}

install_plugin() {
    local plugin_name="$1"
    local plugin_url="$2"
    local plugin_dir="$ZSH_CUSTOM/plugins/$plugin_name"
    
    if [[ -d "$plugin_dir" ]]; then
        log_info "$plugin_name já instalado"
        
        if confirm "Atualizar $plugin_name?"; then
            (cd "$plugin_dir" && git pull) 2>&1 | tee -a "$LOG_FILE"
            log_success "$plugin_name atualizado"
        fi
        
        mark_installed "plugin_${plugin_name}" "installed"
        return 0
    fi
    
    log_info "Instalando $plugin_name..."
    git_clone_safe "$plugin_url" "$plugin_dir" "1"
    
    mark_installed "plugin_${plugin_name}" "installed"
    log_success "$plugin_name instalado"
}

install_all_plugins() {
    mkdir -p "$ZSH_CUSTOM/plugins"
    
    for plugin_name in "${!PLUGINS[@]}"; do
        install_plugin "$plugin_name" "${PLUGINS[$plugin_name]}"
    done
}

configure_plugins_in_zshrc() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "zsh-autosuggestions" "$zshrc" 2>/dev/null; then
        log_info "Plugins já configurados no .zshrc"
        return 0
    fi
    
    log_info "Configurando plugins no .zshrc..."
    
    backup_file "$zshrc"
    
    # Atualizar linha de plugins
    local plugins_line="plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search docker docker-compose npm node)"
    
    # Substituir linha de plugins existente
    sed -i "s/^plugins=.*/$plugins_line/" "$zshrc"
    
    # Registrar rollback
    echo "sed -i 's/^plugins=.*/plugins=(git)/' $zshrc" >> "$ROLLBACK_LOG"
    
    mark_installed "${COMPONENT}_configured" "yes"
}

configure_plugin_settings() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "# Plugin Settings" "$zshrc" 2>/dev/null; then
        log_info "Configurações de plugins já aplicadas"
        return 0
    fi
    
    log_info "Aplicando configurações dos plugins..."
    
    cat >> "$zshrc" << 'EOF'

# ==========================================
# Plugin Settings
# ==========================================

# zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# zsh-syntax-highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# zsh-completions
autoload -U compinit && compinit

EOF
    
    mark_installed "${COMPONENT}_settings" "yes"
}

show_plugins_info() {
    log_info ""
    log_info "═══════════════════════════════════════════════════"
    log_success "Plugins Zsh instalados com sucesso!"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    echo "Plugins instalados:"
    echo "  • zsh-autosuggestions      - Sugestões baseadas no histórico"
    echo "  • zsh-syntax-highlighting  - Destaque de sintaxe em tempo real"
    echo "  • zsh-completions          - Complementos adicionais"
    echo "  • zsh-history-substring-search - Busca no histórico"
    echo ""
    echo "Atalhos:"
    echo "  • Setas ↑/↓  - Buscar no histórico"
    echo "  • Tab        - Autocompletar"
    echo "  • →          - Aceitar sugestão"
    echo ""
    echo "Recarregue o shell: exec zsh"
    echo ""
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section "Plugins Zsh"
    
    check_prerequisites
    install_all_plugins
    configure_plugins_in_zshrc
    configure_plugin_settings
    show_plugins_info
    
    mark_installed "$COMPONENT" "installed"
    
    log_success "Plugins Zsh configurados"
}

main "$@"
