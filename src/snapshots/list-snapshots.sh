#!/bin/bash
#=============================================================================
# list-snapshots.sh - Listar snapshots disponíveis do WSL
#=============================================================================

set -euo pipefail

readonly SNAPSHOT_DIR="/mnt/c/WSL-Snapshots"
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }

#=============================================================================
# Funções
#=============================================================================

format_size() {
    local bytes=$1
    local sizes=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while ((bytes >= 1024 && unit < ${#sizes[@]} - 1)); do
        ((bytes /= 1024))
        ((unit++))
    done
    
    echo "$bytes${sizes[$unit]}"
}

format_date() {
    local file="$1"
    stat -c "%y" "$file" | cut -d'.' -f1
}

show_snapshot_details() {
    local snapshot_file="$1"
    local meta_file="${snapshot_file%.tar*}.meta"
    
    echo ""
    echo "────────────────────────────────────────────────────"
    echo "Snapshot: $(basename "$snapshot_file")"
    echo "────────────────────────────────────────────────────"
    
    # Info básica
    echo "Arquivo:     $snapshot_file"
    echo "Tamanho:     $(du -h "$snapshot_file" | cut -f1)"
    echo "Criado em:   $(format_date "$snapshot_file")"
    
    # Metadados se existir
    if [[ -f "$meta_file" ]]; then
        echo ""
        echo "Metadados:"
        
        while IFS='=' read -r key value; do
            # Pular linhas vazias e comentários
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            
            # Formatar output
            printf "  %-20s %s\n" "$key:" "$value"
        done < "$meta_file"
    fi
    
    echo "────────────────────────────────────────────────────"
}

list_snapshots_table() {
    log_info "Snapshots disponíveis em: $SNAPSHOT_DIR"
    echo ""
    
    printf "%-3s  %-50s  %-10s  %-20s\n" "#" "Nome" "Tamanho" "Data"
    echo "────────────────────────────────────────────────────────────────────────────────────"
    
    local count=0
    for snapshot in "$SNAPSHOT_DIR"/*.tar*; do
        [[ -f "$snapshot" ]] || continue
        
        ((count++))
        local name=$(basename "$snapshot")
        local size=$(du -h "$snapshot" | cut -f1)
        local date=$(format_date "$snapshot")
        
        printf "%-3d  %-50s  %-10s  %-20s\n" "$count" "$name" "$size" "$date"
    done
    
    echo "────────────────────────────────────────────────────────────────────────────────────"
    echo "Total: $count snapshot(s)"
    echo ""
}

interactive_view() {
    list_snapshots_table
    
    local snapshots=("$SNAPSHOT_DIR"/*.tar*)
    local total=${#snapshots[@]}
    
    if [[ $total -eq 0 || ! -f "${snapshots[0]}" ]]; then
        log_warning "Nenhum snapshot encontrado"
        exit 0
    fi
    
    echo "Opções:"
    echo "  1-$total) Ver detalhes do snapshot"
    echo "  d) Deletar snapshot"
    echo "  q) Sair"
    echo ""
    
    read -r -p "Escolha uma opção: " choice
    
    case "$choice" in
        [0-9]*)
            if ((choice >= 1 && choice <= total)); then
                show_snapshot_details "${snapshots[$((choice-1))]}"
                echo ""
                read -r -p "Pressione ENTER para continuar..."
                interactive_view
            else
                log_warning "Opção inválida"
                interactive_view
            fi
            ;;
        d|D)
            read -r -p "Número do snapshot para deletar (1-$total): " del_choice
            if ((del_choice >= 1 && del_choice <= total)); then
                local file_to_delete="${snapshots[$((del_choice-1))]}"
                echo "Você irá deletar: $(basename "$file_to_delete")"
                read -r -p "Tem certeza? (s/N): " confirm
                if [[ "$confirm" =~ ^[sS]$ ]]; then
                    rm -f "$file_to_delete"
                    rm -f "${file_to_delete%.tar*}.meta"
                    log_info "Snapshot deletado"
                fi
                interactive_view
            fi
            ;;
        q|Q)
            exit 0
            ;;
        *)
            log_warning "Opção inválida"
            interactive_view
            ;;
    esac
}

#=============================================================================
# Main
#=============================================================================

main() {
    if [[ ! -d "$SNAPSHOT_DIR" ]]; then
        log_warning "Diretório de snapshots não existe: $SNAPSHOT_DIR"
        echo "Crie um snapshot primeiro: ./create-snapshot.sh"
        exit 1
    fi
    
    # Se passou argumento, mostrar detalhes
    if [[ $# -gt 0 ]]; then
        show_snapshot_details "$1"
    else
        # Modo interativo
        interactive_view
    fi
}

main "$@"
