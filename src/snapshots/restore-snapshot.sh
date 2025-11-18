#!/bin/bash
#=============================================================================
# restore-snapshot.sh - Restaurar snapshot do WSL
#=============================================================================

set -euo pipefail

# Detecta diretório de snapshots
SNAPSHOT_DIR_DEFAULT="/mnt/c/WSL-Snapshots"
WIN_USER=$(ls -1 /mnt/c/Users 2>/dev/null | grep -v "Public\|Default\|All Users" | head -n1)
SNAPSHOT_DIR_USER="/mnt/c/Users/${WIN_USER}/WSL-Snapshots"

if [[ -d "$SNAPSHOT_DIR_DEFAULT" ]]; then
    SNAPSHOT_DIR="$SNAPSHOT_DIR_DEFAULT"
elif [[ -d "$SNAPSHOT_DIR_USER" ]]; then
    SNAPSHOT_DIR="$SNAPSHOT_DIR_USER"
else
    SNAPSHOT_DIR="$SNAPSHOT_DIR_DEFAULT"
fi

readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✔${NC} $*"; }
log_error() { echo -e "${RED}✖${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }

list_snapshots() {
    log_info "Snapshots disponíveis:"
    echo ""
    
    local count=0
    for snapshot in "$SNAPSHOT_DIR"/*.tar*; do
        if [[ -f "$snapshot" ]]; then
            ((count++))
            local name=$(basename "$snapshot")
            local size=$(du -h "$snapshot" | cut -f1)
            local date=$(stat -c %y "$snapshot" | cut -d' ' -f1)
            
            printf "  %2d) %-50s %8s  %s\n" "$count" "$name" "$size" "$date"
            
            # Mostrar metadados se existirem
            local meta_file="${snapshot%.tar*}.meta"
            if [[ -f "$meta_file" ]]; then
                local node_ver=$(grep "NODE_VERSION" "$meta_file" | cut -d= -f2)
                local java_ver=$(grep "JAVA_VERSION" "$meta_file" | cut -d= -f2)
                echo "      Node: $node_ver | Java: $java_ver"
            fi
            echo ""
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        log_warning "Nenhum snapshot encontrado em $SNAPSHOT_DIR"
        exit 1
    fi
    
    return $count
}

restore_snapshot() {
    local snapshot_file="$1"
    local new_distro_name="$2"
    local install_location="/mnt/c/WSL/${new_distro_name}"
    
    # Descomprimir se necessário
    if [[ "$snapshot_file" == *.gz ]]; then
        log_info "Descomprimindo snapshot..."
        gunzip -k "$snapshot_file"
        snapshot_file="${snapshot_file%.gz}"
    fi
    
    log_warning "ATENÇÃO: Esta operação irá:"
    echo "  1. Criar nova distribuição: $new_distro_name"
    echo "  2. Instalar em: $install_location"
    echo ""
    
    read -r -p "Continuar? (s/N): " confirm
    if [[ ! "$confirm" =~ ^[sS]$ ]]; then
        log_info "Operação cancelada"
        exit 0
    fi
    
    log_info "Importando snapshot..."
    wsl.exe --import "$new_distro_name" "$install_location" "$snapshot_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "Snapshot restaurado com sucesso!"
        echo ""
        echo "Para usar a nova distribuição:"
        echo "  wsl -d $new_distro_name"
        echo ""
        echo "Para definir como padrão:"
        echo "  wsl --set-default $new_distro_name"
    else
        log_error "Falha ao restaurar snapshot"
        exit 1
    fi
}

main() {
    log_info "═══════════════════════════════════════════════════"
    log_info "  Restaurar Snapshot do WSL"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    
    if [[ ! -d "$SNAPSHOT_DIR" ]]; then
        log_error "Diretório de snapshots não encontrado: $SNAPSHOT_DIR"
        exit 1
    fi
    
    list_snapshots
    local total=$?
    
    echo ""
    read -r -p "Escolha o número do snapshot (1-$total): " choice
    
    # Encontrar o snapshot escolhido
    local count=0
    for snapshot in "$SNAPSHOT_DIR"/*.tar*; do
        if [[ -f "$snapshot" ]]; then
            ((count++))
            if [[ $count -eq $choice ]]; then
                read -r -p "Nome para a nova distribuição (ex: Ubuntu-Restored): " new_name
                restore_snapshot "$snapshot" "$new_name"
                exit 0
            fi
        fi
    done
    
    log_error "Escolha inválida"
    exit 1
}

main "$@"
