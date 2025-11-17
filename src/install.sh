#!/bin/bash
#=============================================================================
# install.sh - Orquestrador principal de instalação idempotente
# Uso: ./install.sh [opções]
#
# Opções:
#   --full              Instalação completa
#   --minimal           Instalação mínima (zsh + essentials)
#   --components        Escolher componentes interativamente
#   --skip-snapshot     Não criar snapshot antes de instalar
#   --rollback          Reverter instalação
#   --list              Listar componentes instalados
#   --help              Exibir ajuda
#=============================================================================

set -euo pipefail

# Diretórios
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly MODULES_DIR="$SCRIPT_DIR/modules"
readonly SNAPSHOTS_DIR="$SCRIPT_DIR/snapshots"

# Carregar bibliotecas
source "$LIB_DIR/core.sh"
source "$LIB_DIR/idempotent.sh"
source "$LIB_DIR/rollback.sh"

#=============================================================================
# Configuração de Instalação
#=============================================================================

declare -A COMPONENTS=(
    ["system"]="01-system.sh"
    ["zsh"]="02-zsh.sh"
    ["powerlevel10k"]="03-powerlevel10k.sh"
    ["plugins"]="04-plugins.sh"
    ["fzf"]="05-fzf.sh"
    ["nodejs"]="06-nodejs.sh"
    ["java"]="07-java.sh"
    ["php"]="08-php.sh"
    ["dotnet"]="09-dotnet.sh"
    ["docker"]="10-docker.sh"
    ["extras"]="11-extras.sh"
)

declare -a MINIMAL_INSTALL=("system" "zsh" "powerlevel10k" "plugins" "fzf")
declare -a FULL_INSTALL=("${!COMPONENTS[@]}")

#=============================================================================
# Funções de Instalação
#=============================================================================

install_component() {
    local component="$1"
    local module_file="$MODULES_DIR/${COMPONENTS[$component]}"
    
    if [[ ! -f "$module_file" ]]; then
        log_error "Módulo não encontrado: $module_file"
        return 1
    fi
    
    log_section "Instalando: $component"
    
    # Executar módulo
    bash "$module_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "$component instalado com sucesso"
        return 0
    else
        log_error "Falha ao instalar $component"
        return 1
    fi
}

install_components() {
    local components=("$@")
    local total=${#components[@]}
    local current=0
    
    for component in "${components[@]}"; do
        ((current++))
        show_progress $current $total
        echo ""
        
        if is_installed "$component"; then
            log_info "$component já instalado (pulando)"
            continue
        fi
        
        install_component "$component" || {
            log_error "Falha ao instalar $component"
            if confirm "Continuar com próximo componente?"; then
                continue
            else
                log_warning "Instalação interrompida pelo usuário"
                return 1
            fi
        }
    done
    
    echo ""
    log_success "Instalação concluída!"
}

#=============================================================================
# Menu Interativo
#=============================================================================

interactive_menu() {
    log_section "Instalação Interativa"
    
    echo "Escolha os componentes para instalar:"
    echo ""
    
    local -a selected=()
    local -A choices
    
    for component in "${!COMPONENTS[@]}"; do
        if is_installed "$component"; then
            echo "  [✓] $component (já instalado)"
        else
            echo "  [ ] $component"
        fi
    done
    
    echo ""
    echo "Digite os componentes separados por espaço (ex: nodejs java docker)"
    echo "ou digite 'all' para instalar tudo:"
    echo ""
    
    read -r -a selected
    
    if [[ "${selected[0]}" == "all" ]]; then
        selected=("${FULL_INSTALL[@]}")
    fi
    
    echo ""
    log_info "Componentes selecionados: ${selected[*]}"
    echo ""
    
    if confirm "Confirmar instalação?"; then
        install_components "${selected[@]}"
    else
        log_info "Instalação cancelada"
    fi
}

#=============================================================================
# Criar Snapshot Pré-Instalação
#=============================================================================

create_pre_install_snapshot() {
    log_section "Snapshot Pré-Instalação"
    
    if confirm "Criar snapshot antes de instalar?"; then
        bash "$SNAPSHOTS_DIR/create-snapshot.sh"
        log_success "Snapshot criado. Você pode restaurá-lo em caso de problemas"
    else
        log_warning "Pulando criação de snapshot"
    fi
}

#=============================================================================
# Sumário Pós-Instalação
#=============================================================================

show_summary() {
    log_section "Sumário da Instalação"
    
    list_installed_components
    
    echo ""
    echo "Logs disponíveis em: $LOG_DIR"
    echo "Estado salvo em: $STATE_DIR"
    echo ""
    echo "Comandos úteis:"
    echo "  • Ver componentes: $SCRIPT_DIR/install.sh --list"
    echo "  • Rollback: $SCRIPT_DIR/install.sh --rollback"
    echo "  • Criar snapshot: $SNAPSHOTS_DIR/create-snapshot.sh"
    echo ""
}

#=============================================================================
# Main
#=============================================================================

show_help() {
    cat << EOF
Uso: $(basename "$0") [opções]

Opções:
  --full              Instalação completa de todos os componentes
  --minimal           Instalação mínima (zsh, terminal, essentials)
  --components        Menu interativo para escolher componentes
  --skip-snapshot     Não criar snapshot antes de instalar
  --rollback          Reverter instalação (menu interativo)
  --list              Listar componentes instalados
  --help              Exibir esta ajuda

Exemplos:
  $(basename "$0") --full
  $(basename "$0") --minimal --skip-snapshot
  $(basename "$0") --components
  $(basename "$0") --rollback

EOF
}

main() {
    # Banner
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🚀  WSL 2 + Ubuntu - Instalação Automatizada              ║
║   Sistema Idempotente com Rollback                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo ""
    
    # Validações
    pre_install_checks
    
    # Parse argumentos
    local skip_snapshot=false
    local mode="interactive"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --full)
                mode="full"
                shift
                ;;
            --minimal)
                mode="minimal"
                shift
                ;;
            --components)
                mode="interactive"
                shift
                ;;
            --skip-snapshot)
                skip_snapshot=true
                shift
                ;;
            --rollback)
                interactive_rollback
                exit 0
                ;;
            --list)
                list_installed_components
                exit 0
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Snapshot pré-instalação
    if [[ "$skip_snapshot" == false ]]; then
        create_pre_install_snapshot
    fi
    
    # Executar instalação conforme modo
    case "$mode" in
        full)
            log_info "Modo: Instalação Completa"
            install_components "${FULL_INSTALL[@]}"
            ;;
        minimal)
            log_info "Modo: Instalação Mínima"
            install_components "${MINIMAL_INSTALL[@]}"
            ;;
        interactive)
            interactive_menu
            ;;
    esac
    
    # Sumário
    show_summary
}

main "$@"
