#!/bin/bash
#=============================================================================
# create-snapshot.sh - Criar snapshot do WSL Ubuntu
# Baseado em: https://learn.microsoft.com/windows/wsl/
#=============================================================================

set -euo pipefail

# Configurações
readonly SNAPSHOT_DIR="/mnt/c/WSL-Snapshots"
readonly DISTRO_NAME="Ubuntu"
readonly TIMESTAMP=$(date +%Y%m%d-%H%M%S)
readonly SNAPSHOT_NAME="${DISTRO_NAME}-snapshot-${TIMESTAMP}"
readonly SNAPSHOT_FILE="${SNAPSHOT_DIR}/${SNAPSHOT_NAME}.tar"
readonly METADATA_FILE="${SNAPSHOT_DIR}/${SNAPSHOT_NAME}.meta"

# Cores
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

#=============================================================================
# Funções
#=============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✔${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

create_snapshot_dir() {
    if [[ ! -d "$SNAPSHOT_DIR" ]]; then
        mkdir -p "$SNAPSHOT_DIR"
        log_info "Diretório de snapshots criado: $SNAPSHOT_DIR"
    fi
}

save_metadata() {
    cat > "$METADATA_FILE" << EOF
SNAPSHOT_NAME=$SNAPSHOT_NAME
DISTRO_NAME=$DISTRO_NAME
CREATED_AT=$(date -Iseconds)
HOSTNAME=$(hostname)
USER=$USER
KERNEL=$(uname -r)
WSL_VERSION=$(wsl.exe --version 2>/dev/null | head -n1 || echo "WSL 2")

# Versões de Ferramentas Instaladas
NODE_VERSION=$(node -v 2>/dev/null || echo "não instalado")
JAVA_VERSION=$(java -version 2>&1 | head -n1 || echo "não instalado")
DOCKER_VERSION=$(docker --version 2>/dev/null || echo "não instalado")
PHP_VERSION=$(php -v 2>/dev/null | head -n1 || echo "não instalado")
DOTNET_VERSION=$(dotnet --version 2>/dev/null || echo "não instalado")

# Estado da Instalação
INSTALLED_COMPONENTS=$(ls ~/.wsl-setup/state/*.installed 2>/dev/null | wc -l)
EOF
    
    log_success "Metadados salvos: $METADATA_FILE"
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_info "═══════════════════════════════════════════════════"
    log_info "  Criando Snapshot do WSL Ubuntu"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    
    # Verificações
    if ! grep -qiE '(Microsoft|WSL)' /proc/version; then
        echo "Erro: Este script deve ser executado dentro do WSL"
        exit 1
    fi
    
    create_snapshot_dir
    
    # Salvar metadados primeiro
    log_info "Salvando metadados do sistema..."
    save_metadata
    
    # Exportar WSL
    log_info "Exportando distribuição WSL..."
    log_warning "Este processo pode levar vários minutos..."
    echo ""
    
    wsl.exe --export "$DISTRO_NAME" "$SNAPSHOT_FILE"
    
    if [[ -f "$SNAPSHOT_FILE" ]]; then
        local size_mb
        size_mb=$(du -m "$SNAPSHOT_FILE" | cut -f1)
        
        log_success "Snapshot criado com sucesso!"
        echo ""
        echo "  Nome: $SNAPSHOT_NAME"
        echo "  Arquivo: $SNAPSHOT_FILE"
        echo "  Tamanho: ${size_mb} MB"
        echo "  Metadados: $METADATA_FILE"
        echo ""
        
        # Comprimir (opcional)
        read -r -p "Deseja comprimir o snapshot? (s/N): " compress
        if [[ "$compress" =~ ^[sS]$ ]]; then
            log_info "Comprimindo snapshot..."
            gzip -9 "$SNAPSHOT_FILE"
            log_success "Snapshot comprimido: ${SNAPSHOT_FILE}.gz"
        fi
    else
        echo "Erro: Falha ao criar snapshot"
        exit 1
    fi
}

main "$@"
