#!/bin/bash
#=============================================================================
# 06-nodejs.sh - Instalação idempotente do Node.js via fnm
#=============================================================================

set -euo pipefail

# Carregar bibliotecas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="nodejs"
readonly FNM_INSTALL_URL="https://fnm.vercel.app/install"

#=============================================================================
# Instalação
#=============================================================================

install_fnm() {
    if command_exists fnm; then
        local version
        version=$(fnm --version 2>/dev/null || echo "unknown")
        log_info "fnm já instalado: $version"
        mark_installed "fnm" "$version"
        return 0
    fi
    
    log_info "Instalando fnm..."
    download_and_run "$FNM_INSTALL_URL" "fnm" "fnm"
    
    # Configurar no .zshrc
    append_once "$HOME/.zshrc" 'eval "$(fnm env --use-on-cd)"' "fnm env"
}

install_nodejs() {
    # fnm deve estar no PATH
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env)" 2>/dev/null || true
    
    if command_exists node; then
        local version
        version=$(node -v)
        log_info "Node.js já instalado: $version"
        mark_installed "nodejs" "$version"
        return 0
    fi
    
    log_info "Instalando Node.js LTS..."
    fnm install --lts
    fnm default lts-latest
    
    local version
    version=$(node -v)
    mark_installed "nodejs" "$version"
    log_success "Node.js instalado: $version"
}

install_pnpm() {
    if command_exists pnpm; then
        local version
        version=$(pnpm -v)
        log_info "pnpm já instalado: $version"
        mark_installed "pnpm" "$version"
        return 0
    fi
    
    log_info "Instalando pnpm via Corepack..."
    corepack enable
    corepack prepare pnpm@latest --activate
    
    local version
    version=$(pnpm -v)
    mark_installed "pnpm" "$version"
    log_success "pnpm instalado: $version"
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section "Node.js + fnm + pnpm"
    
    install_fnm
    install_nodejs
    install_pnpm
    
    mark_installed "$COMPONENT" "$(node -v 2>/dev/null || echo 'pending')"
    
    log_success "Módulo Node.js concluído"
}

main "$@"
