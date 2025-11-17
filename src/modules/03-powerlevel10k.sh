#!/bin/bash
#=============================================================================
# 03-powerlevel10k.sh - Instalação do tema Powerlevel10k
#=============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="powerlevel10k"
readonly P10K_REPO="https://github.com/romkatv/powerlevel10k.git"
readonly ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
readonly P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

#=============================================================================
# Funções
#=============================================================================

check_prerequisites() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_error "Oh My Zsh não instalado. Execute: modules/02-zsh.sh"
        exit 1
    fi
}

install_fonts_info() {
    log_info "═══════════════════════════════════════════════════"
    log_warning "IMPORTANTE: Instale uma Nerd Font no Windows!"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    echo "Recomendadas:"
    echo "  • MesloLGS NF (recomendada pelo Powerlevel10k)"
    echo "  • JetBrainsMono Nerd Font"
    echo "  • FiraCode Nerd Font"
    echo ""
    echo "Download: https://www.nerdfonts.com/font-downloads"
    echo ""
    echo "Após instalar no Windows:"
    echo "  1. Abra Windows Terminal"
    echo "  2. Settings → Perfil Ubuntu → Appearance"
    echo "  3. Font face → Selecione a Nerd Font instalada"
    echo ""
    
    if ! confirm "Nerd Font instalada no Windows?"; then
        log_warning "Configure a fonte antes de prosseguir para evitar caracteres quebrados"
        if ! confirm "Continuar mesmo assim?"; then
            exit 0
        fi
    fi
}

install_powerlevel10k() {
    if [[ -d "$P10K_DIR" ]]; then
        log_info "Powerlevel10k já instalado"
        
        if confirm "Atualizar Powerlevel10k?"; then
            (cd "$P10K_DIR" && git pull) 2>&1 | tee -a "$LOG_FILE"
            log_success "Powerlevel10k atualizado"
        fi
        
        mark_installed "$COMPONENT" "$(cd "$P10K_DIR" && git describe --tags)"
        return 0
    fi
    
    log_info "Clonando Powerlevel10k..."
    git_clone_safe "$P10K_REPO" "$P10K_DIR" "1"
    
    mark_installed "$COMPONENT" "$(cd "$P10K_DIR" && git describe --tags)"
}

configure_theme() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "powerlevel10k/powerlevel10k" "$zshrc" 2>/dev/null; then
        log_info "Tema já configurado no .zshrc"
        return 0
    fi
    
    log_info "Configurando tema no .zshrc..."
    
    backup_file "$zshrc"
    
    # Substituir linha do tema
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"
    
    # Registrar rollback
    echo "sed -i 's/^ZSH_THEME=.*/ZSH_THEME=\"robbyrussell\"/' $zshrc" >> "$ROLLBACK_LOG"
}

install_p10k_config() {
    local p10k_config="$HOME/.p10k.zsh"
    
    if [[ -f "$p10k_config" ]] && is_installed "${COMPONENT}_config"; then
        log_info "Configuração .p10k.zsh já existe"
        return 0
    fi
    
    log_info "Instalando configuração base do Powerlevel10k..."
    
    # Se existir template customizado, usar
    if [[ -f "$SCRIPT_DIR/config/templates/.p10k.zsh.template" ]]; then
        cp "$SCRIPT_DIR/config/templates/.p10k.zsh.template" "$p10k_config"
        log_info "Template customizado aplicado"
    else
        # Baixar configuração padrão
        curl -fsSL https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-rainbow.zsh \
            -o "$p10k_config" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Adicionar source no .zshrc se não existir
    local zshrc="$HOME/.zshrc"
    if ! grep -q "source ~/.p10k.zsh" "$zshrc"; then
        echo "" >> "$zshrc"
        echo "# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$zshrc"
        echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$zshrc"
    fi
    
    mark_installed "${COMPONENT}_config" "yes"
}

configure_instant_prompt() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "p10k-instant-prompt" "$zshrc" 2>/dev/null; then
        log_info "Instant prompt já configurado"
        return 0
    fi
    
    log_info "Configurando instant prompt..."
    
    backup_file "$zshrc"
    
    # Adicionar no início do .zshrc
    cat > /tmp/p10k-instant-prompt.txt << 'EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

EOF
    
    # Inserir no início do arquivo
    cat /tmp/p10k-instant-prompt.txt "$zshrc" > /tmp/zshrc.tmp
    mv /tmp/zshrc.tmp "$zshrc"
    rm /tmp/p10k-instant-prompt.txt
}

show_next_steps() {
    log_info ""
    log_info "═══════════════════════════════════════════════════"
    log_success "Powerlevel10k instalado com sucesso!"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    echo "Próximos passos:"
    echo "  1. Recarregue o shell: exec zsh"
    echo "  2. O assistente de configuração será iniciado"
    echo "  3. Para reconfigurar depois: p10k configure"
    echo ""
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section "Powerlevel10k Theme"
    
    check_prerequisites
    install_fonts_info
    install_powerlevel10k
    configure_theme
    install_p10k_config
    configure_instant_prompt
    show_next_steps
    
    mark_installed "$COMPONENT" "installed"
    
    log_success "Powerlevel10k configurado"
}

main "$@"
