#!/bin/bash
#=============================================================================
# 10-docker.sh - Configuração do Docker no WSL
#=============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="docker"

#=============================================================================
# Funções
#=============================================================================

check_docker_desktop() {
    log_info "Verificando Docker Desktop..."
    
    if command_exists docker && docker ps >/dev/null 2>&1; then
        log_success "Docker Desktop detectado e funcionando"
        return 0
    else
        log_warning "Docker Desktop não detectado ou não está rodando"
        return 1
    fi
}

install_docker_cli() {
    if command_exists docker; then
        local version
        version=$(docker --version | cut -d' ' -f3 | tr -d ',')
        log_info "Docker CLI já instalado: $version"
        mark_installed "docker_cli" "$version"
        return 0
    fi
    
    log_info "Instalando Docker CLI..."
    
    # Adicionar repositório Docker
    apt_install ca-certificates curl gnupg
    
    # Adicionar chave GPG
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>&1 | tee -a "$LOG_FILE"
    
    # Adicionar repositório
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update 2>&1 | tee -a "$LOG_FILE"
    
    # Instalar apenas CLI e Compose plugin
    apt_install docker-ce-cli docker-compose-plugin
    
    local version
    version=$(docker --version | cut -d' ' -f3 | tr -d ',')
    mark_installed "docker_cli" "$version"
    log_success "Docker CLI instalado: $version"
}

configure_docker_group() {
    if groups "$USER" | grep -q docker; then
        log_info "Usuário já está no grupo docker"
        return 0
    fi
    
    log_info "Adicionando usuário ao grupo docker..."
    
    # Criar grupo se não existir
    sudo groupadd docker 2>/dev/null || true
    
    # Adicionar usuário
    sudo usermod -aG docker "$USER"
    
    # Registrar para rollback
    echo "sudo gpasswd -d $USER docker" >> "$ROLLBACK_LOG"
    
    log_success "Usuário adicionado ao grupo docker"
    log_warning "Execute 'newgrp docker' ou reinicie o terminal para aplicar"
}

configure_docker_buildkit() {
    local docker_config="$HOME/.docker/config.json"
    
    if [[ -f "$docker_config" ]] && grep -q "buildkit" "$docker_config"; then
        log_info "BuildKit já configurado"
        return 0
    fi
    
    log_info "Habilitando Docker BuildKit..."
    
    mkdir -p "$HOME/.docker"
    
    if [[ -f "$docker_config" ]]; then
        backup_file "$docker_config"
    fi
    
    cat > "$docker_config" << 'EOF'
{
  "features": {
    "buildkit": true
  },
  "experimental": "enabled"
}
EOF
    
    mark_installed "${COMPONENT}_buildkit" "enabled"
}

create_docker_aliases() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "# Docker Aliases" "$zshrc" 2>/dev/null; then
        log_info "Aliases Docker já configurados"
        return 0
    fi
    
    log_info "Criando aliases úteis para Docker..."
    
    cat >> "$zshrc" << 'EOF'

# ==========================================
# Docker Aliases
# ==========================================

# Container management
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dstart='docker start'
alias dstop='docker stop'
alias drm='docker rm'
alias drmf='docker rm -f'

# Image management
alias di='docker images'
alias drmi='docker rmi'
alias dpull='docker pull'
alias dbuild='docker build'

# Docker Compose
alias dc='docker compose'
alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dclogs='docker compose logs -f'
alias dcps='docker compose ps'
alias dcrestart='docker compose restart'

# Cleanup
alias docker-clean='docker system prune -af --volumes'
alias docker-clean-containers='docker container prune -f'
alias docker-clean-images='docker image prune -af'
alias docker-clean-volumes='docker volume prune -f'

# Logs
alias dlogs='docker logs -f'

# Execute bash in container
dexec() {
    docker exec -it "$1" /bin/bash
}

# Execute sh in container (fallback)
dexecsh() {
    docker exec -it "$1" /bin/sh
}

EOF
    
    mark_installed "${COMPONENT}_aliases" "yes"
}

test_docker_installation() {
    log_info "Testando instalação do Docker..."
    
    if ! docker ps >/dev/null 2>&1; then
        log_warning "Docker não está acessível. Possíveis causas:"
        echo "  1. Docker Desktop não está rodando no Windows"
        echo "  2. WSL Integration não está habilitado no Docker Desktop"
        echo "  3. Você precisa relogar ou executar: newgrp docker"
        echo ""
        echo "Para habilitar WSL Integration:"
        echo "  Docker Desktop → Settings → Resources → WSL Integration"
        echo "  → Habilite seu Ubuntu"
        return 1
    fi
    
    log_info "Executando 'docker run hello-world'..."
    if docker run --rm hello-world 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Docker funcionando corretamente!"
        return 0
    else
        log_error "Falha ao executar container de teste"
        return 1
    fi
}

show_docker_info() {
    log_info ""
    log_info "═══════════════════════════════════════════════════"
    log_success "Docker configurado com sucesso!"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    
    if command_exists docker; then
        docker --version
        docker compose version
        echo ""
    fi
    
    echo "Aliases criados:"
    echo "  • dps / dpsa      - Listar containers"
    echo "  • dcup / dcdown   - Docker Compose up/down"
    echo "  • dclogs          - Logs do Docker Compose"
    echo "  • docker-clean    - Limpar tudo"
    echo "  • dexec <id>      - Bash no container"
    echo ""
    echo "Configure Docker Desktop:"
    echo "  Settings → Resources → WSL Integration"
    echo "  → Marque seu Ubuntu como enabled"
    echo ""
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section "Docker no WSL"
    
    if check_docker_desktop; then
        log_info "Usando Docker Desktop (recomendado)"
        configure_docker_group
    else
        log_info "Docker Desktop não detectado, instalando CLI..."
        install_docker_cli
        configure_docker_group
        
        log_warning ""
        log_warning "RECOMENDAÇÃO: Instale o Docker Desktop no Windows"
        log_warning "É a forma mais estável e performática no WSL"
        log_warning "Download: https://www.docker.com/products/docker-desktop/"
        echo ""
        
        if ! confirm "Continuar sem Docker Desktop?"; then
            exit 0
        fi
    fi
    
    configure_docker_buildkit
    create_docker_aliases
    
    # Aplicar grupo docker na sessão atual
    newgrp docker << EONG
        $(declare -f test_docker_installation)
        $(declare -f log_info)
        $(declare -f log_success)
        $(declare -f log_error)
        $(declare -f log_warning)
        test_docker_installation
EONG
    
    show_docker_info
    
    mark_installed "$COMPONENT" "$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo 'cli-only')"
    
    log_success "Docker configurado"
}

main "$@"
