#!/bin/bash
#=============================================================================
# core.sh - Funções essenciais para instalação idempotente
# Baseado em melhores práticas: arslan.io/idempotent-bash
#=============================================================================

set -euo pipefail
IFS=$'\n\t'

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Diretórios
# Define SCRIPT_DIR apenas se ainda não foi definido
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    readonly SCRIPT_DIR
fi
readonly LOG_DIR="$HOME/.wsl-setup/logs"
readonly STATE_DIR="$HOME/.wsl-setup/state"
readonly BACKUP_DIR="$HOME/.wsl-setup/backups"
readonly ROLLBACK_LOG="$STATE_DIR/rollback.log"

# Criação de diretórios necessários
mkdir -p "$LOG_DIR" "$STATE_DIR" "$BACKUP_DIR"

# Arquivo de log com timestamp
readonly LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"

#=============================================================================
# Funções de Logging
#=============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✔${NC} $*" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}✖${NC} $*" | tee -a "$LOG_FILE" >&2
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
    echo -e "${BLUE}▶${NC} $*" | tee -a "$LOG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
}

#=============================================================================
# Funções de Estado
#=============================================================================

# Marca um componente como instalado
mark_installed() {
    local component="$1"
    local version="${2:-unknown}"
    echo "$version" > "$STATE_DIR/${component}.installed"
    log "INFO" "Marcado como instalado: $component (versão: $version)"
}

# Verifica se um componente já está instalado
is_installed() {
    local component="$1"
    [[ -f "$STATE_DIR/${component}.installed" ]]
}

# Obtém versão instalada
get_installed_version() {
    local component="$1"
    if is_installed "$component"; then
        cat "$STATE_DIR/${component}.installed"
    else
        echo "not_installed"
    fi
}

# Remove marca de instalação (para rollback)
unmark_installed() {
    local component="$1"
    rm -f "$STATE_DIR/${component}.installed"
    log "INFO" "Desmarcado: $component"
}

#=============================================================================
# Funções de Validação
#=============================================================================

# Verifica se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verifica se está rodando no WSL
is_wsl() {
    grep -qiE '(Microsoft|WSL)' /proc/version 2>/dev/null
}

# Verifica se tem acesso à internet
check_internet() {
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_error "Sem conexão com a internet"
        return 1
    fi
    return 0
}

# Verifica se é Ubuntu
is_ubuntu() {
    [[ -f /etc/os-release ]] && grep -q "Ubuntu" /etc/os-release
}

# Validações pré-instalação
pre_install_checks() {
    log_section "Validações Pré-Instalação"
    
    if ! is_wsl; then
        log_error "Este script deve ser executado no WSL"
        exit 1
    fi
    
    if ! is_ubuntu; then
        log_error "Este script foi projetado para Ubuntu"
        exit 1
    fi
    
    if ! check_internet; then
        log_error "Conexão com internet necessária"
        exit 1
    fi
    
    log_success "Todas as validações passaram"
}

#=============================================================================
# Funções de Backup
#=============================================================================

# Backup de arquivo/diretório
backup_file() {
    local source="$1"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    
    if [[ -e "$source" ]]; then
        local backup_path="$BACKUP_DIR/$(basename "$source").$timestamp"
        cp -r "$source" "$backup_path"
        log_info "Backup criado: $backup_path"
        echo "$backup_path" >> "$STATE_DIR/backups.list"
        return 0
    fi
    return 1
}

#=============================================================================
# Tratamento de Erros
#=============================================================================

# Trap para capturar erros
error_handler() {
    local line_no=$1
    log_error "Erro na linha $line_no"
    log_error "Executando rollback automático..."
    
    if [[ -f "$SCRIPT_DIR/lib/rollback.sh" ]]; then
        source "$SCRIPT_DIR/lib/rollback.sh"
        auto_rollback
    fi
    
    exit 1
}

trap 'error_handler $LINENO' ERR

#=============================================================================
# Funções Utilitárias
#=============================================================================

# Aguarda confirmação do usuário
confirm() {
    local prompt="$1"
    local response
    
    read -r -p "${prompt} (s/N): " response
    case "$response" in
        [sS][iI][mM]|[sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Exibe progresso
show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    printf "\rProgresso: [%-50s] %d%%" $(printf '#%.0s' $(seq 1 $((percent / 2)))) "$percent"
}

#=============================================================================
# Exportar funções
#=============================================================================

export -f log log_info log_success log_warning log_error log_section
export -f mark_installed is_installed get_installed_version unmark_installed
export -f command_exists is_wsl check_internet is_ubuntu
export -f backup_file confirm show_progress

# Marcar que core.sh foi carregado
readonly CORE_SH_LOADED=1
