#!/bin/bash
#=============================================================================
# 09-dotnet.sh - Instalação do .NET SDK 8.0
#=============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="dotnet"
readonly DOTNET_VERSION="${DOTNET_VERSION:-8.0}"

#=============================================================================
# Funções
#=============================================================================

add_microsoft_repository() {
    if is_installed "${COMPONENT}_repo_added"; then
        log_info "Repositório Microsoft já adicionado"
        return 0
    fi
    
    log_info "Adicionando repositório Microsoft..."
    
    local ubuntu_version
    ubuntu_version=$(lsb_release -rs)
    
    # Baixar pacote de configuração
    wget "https://packages.microsoft.com/config/ubuntu/${ubuntu_version}/packages-microsoft-prod.deb" \
        -O /tmp/packages-microsoft-prod.deb 2>&1 | tee -a "$LOG_FILE"
    
    # Instalar pacote
    sudo dpkg -i /tmp/packages-microsoft-prod.deb 2>&1 | tee -a "$LOG_FILE"
    rm /tmp/packages-microsoft-prod.deb
    
    # Atualizar cache
    sudo apt-get update 2>&1 | tee -a "$LOG_FILE"
    
    mark_installed "${COMPONENT}_repo_added" "yes"
}

install_dotnet_sdk() {
    if command_exists dotnet; then
        local version
        version=$(dotnet --version)
        log_info ".NET SDK já instalado: $version"
        mark_installed "dotnet_sdk" "$version"
        
        # Verificar se é a versão desejada
        if [[ ! "$version" =~ ^$DOTNET_VERSION ]]; then
            log_warning "Versão instalada ($version) difere da desejada ($DOTNET_VERSION)"
            if confirm "Instalar .NET $DOTNET_VERSION?"; then
                : # Continua
            else
                return 0
            fi
        else
            return 0
        fi
    fi
    
    log_info "Instalando .NET SDK $DOTNET_VERSION..."
    apt_install "dotnet-sdk-${DOTNET_VERSION}"
    
    local version
    version=$(dotnet --version)
    mark_installed "dotnet_sdk" "$version"
    log_success ".NET SDK instalado: $version"
}

configure_dotnet_environment() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "DOTNET_ROOT" "$zshrc" 2>/dev/null; then
        log_info "Variáveis .NET já configuradas"
        return 0
    fi
    
    log_info "Configurando variáveis de ambiente .NET..."
    
    cat >> "$zshrc" << 'EOF'

# ==========================================
# .NET Configuration
# ==========================================
export DOTNET_ROOT=/usr/share/dotnet
export PATH="$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools"

# Desabilitar telemetria (opcional)
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Desabilitar .NET welcome message
export DOTNET_NOLOGO=1

EOF
    
    mark_installed "${COMPONENT}_env_configured" "yes"
}

install_dotnet_tools() {
    if ! command_exists dotnet; then
        log_warning ".NET não disponível, pulando ferramentas"
        return 0
    fi
    
    if is_installed "${COMPONENT}_tools"; then
        log_info "Ferramentas .NET já instaladas"
        return 0
    fi
    
    log_info "Instalando ferramentas globais do .NET..."
    
    # Entity Framework Core Tools
    dotnet tool install --global dotnet-ef 2>&1 | tee -a "$LOG_FILE" || log_warning "Falha ao instalar dotnet-ef"
    
    # ASP.NET Core Code Generator
    dotnet tool install --global dotnet-aspnet-codegenerator 2>&1 | tee -a "$LOG_FILE" || log_warning "Falha ao instalar codegenerator"
    
    # Code Formatter
    dotnet tool install --global dotnet-format 2>&1 | tee -a "$LOG_FILE" || log_warning "Falha ao instalar dotnet-format"
    
    mark_installed "${COMPONENT}_tools" "yes"
    log_success "Ferramentas .NET instaladas"
}

show_dotnet_info() {
    log_info ""
    log_info "═══════════════════════════════════════════════════"
    log_success ".NET SDK instalado com sucesso!"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    dotnet --version
    echo ""
    echo "SDKs instalados:"
    dotnet --list-sdks
    echo ""
    echo "Runtimes instalados:"
    dotnet --list-runtimes
    echo ""
    echo "Ferramentas globais:"
    dotnet tool list --global
    echo ""
    echo "Comandos úteis:"
    echo "  • dotnet new console     - Criar app console"
    echo "  • dotnet new webapi      - Criar Web API"
    echo "  • dotnet run             - Executar aplicação"
    echo "  • dotnet ef              - Entity Framework CLI"
    echo ""
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section ".NET SDK $DOTNET_VERSION"
    
    add_microsoft_repository
    install_dotnet_sdk
    configure_dotnet_environment
    install_dotnet_tools
    show_dotnet_info
    
    mark_installed "$COMPONENT" "$(dotnet --version)"
    
    log_success ".NET SDK configurado"
}

main "$@"
