#!/bin/bash
#=============================================================================
# rollback.sh - Sistema de reversão de instalação
#=============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

#=============================================================================
# Rollback Automático
#=============================================================================

auto_rollback() {
    log_section "INICIANDO ROLLBACK AUTOMÁTICO"
    
    if [[ ! -f "$ROLLBACK_LOG" ]]; then
        log_warning "Nenhuma ação para desfazer"
        return 0
    fi
    
    # Executa comandos de rollback em ordem reversa
    tac "$ROLLBACK_LOG" | while read -r command; do
        log_info "Revertendo: $command"
        eval "$command" 2>&1 | tee -a "$LOG_FILE" || log_warning "Falha ao reverter: $command"
    done
    
    # Restaura backups
    restore_backups
    
    # Limpa estado
    rm -rf "$STATE_DIR"/*.installed
    rm -f "$ROLLBACK_LOG"
    
    log_success "Rollback concluído"
}

#=============================================================================
# Rollback Manual (Componente Específico)
#=============================================================================

rollback_component() {
    local component="$1"
    
    log_section "Rollback: $component"
    
    if ! is_installed "$component"; then
        log_warning "$component não está marcado como instalado"
        return 1
    fi
    
    # Procura ações específicas do componente no log de rollback
    if [[ -f "$ROLLBACK_LOG" ]]; then
        grep "$component" "$ROLLBACK_LOG" | tac | while read -r command; do
            log_info "Revertendo: $command"
            eval "$command" 2>&1 | tee -a "$LOG_FILE"
        done
    fi
    
    unmark_installed "$component"
    log_success "Rollback de $component concluído"
}

#=============================================================================
# Restaurar Backups
#=============================================================================

restore_backups() {
    log_info "Restaurando backups..."
    
    if [[ ! -f "$STATE_DIR/backups.list" ]]; then
        log_info "Nenhum backup para restaurar"
        return 0
    fi
    
    while read -r backup_path; do
        if [[ -f "$backup_path" ]]; then
            local original_path="${backup_path%.*}"  # Remove timestamp
            cp "$backup_path" "$original_path"
            log_info "Restaurado: $original_path"
        fi
    done < "$STATE_DIR/backups.list"
    
    rm -f "$STATE_DIR/backups.list"
}

#=============================================================================
# Listar Componentes Instalados
#=============================================================================

list_installed_components() {
    log_section "Componentes Instalados"
    
    local count=0
    for file in "$STATE_DIR"/*.installed; do
        if [[ -f "$file" ]]; then
            local component
            component="$(basename "$file" .installed)"
            local version
            version="$(cat "$file")"
            echo "  ✓ $component (versão: $version)"
            ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        echo "  Nenhum componente instalado"
    else
        echo ""
        echo "Total: $count componentes"
    fi
}

#=============================================================================
# Rollback Interativo
#=============================================================================

interactive_rollback() {
    log_section "Rollback Interativo"
    
    list_installed_components
    
    echo ""
    echo "Opções:"
    echo "  1) Rollback completo (todos os componentes)"
    echo "  2) Rollback de componente específico"
    echo "  3) Cancelar"
    echo ""
    
    read -r -p "Escolha uma opção: " option
    
    case "$option" in
        1)
            if confirm "Tem certeza que deseja remover TUDO?"; then
                auto_rollback
            fi
            ;;
        2)
            read -r -p "Nome do componente: " component
            rollback_component "$component"
            ;;
        *)
            log_info "Operação cancelada"
            ;;
    esac
}

#=============================================================================
# Exportar funções
#=============================================================================

export -f auto_rollback rollback_component restore_backups
export -f list_installed_components interactive_rollback
