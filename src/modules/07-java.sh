#!/bin/bash
#=============================================================================
# 07-java.sh - Instalação de Java, Maven e Gradle via SDKMAN!
#=============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="java"
readonly SDKMAN_URL="https://get.sdkman.io"
readonly SDKMAN_DIR="$HOME/.sdkman"

# Carregar configurações
JAVA_VERSION="${JAVA_VERSION:-21.0.5-tem}"
MAVEN_VERSION="${MAVEN_VERSION:-latest}"
GRADLE_VERSION="${GRADLE_VERSION:-latest}"

#=============================================================================
# Funções
#=============================================================================

install_prerequisites() {
    log_info "Instalando dependências..."
    apt_install zip unzip
}

install_sdkman() {
    if [[ -d "$SDKMAN_DIR" ]]; then
        log_info "SDKMAN já instalado"
        mark_installed "sdkman" "$(cat "$SDKMAN_DIR/var/version" 2>/dev/null || echo 'unknown')"
        return 0
    fi
    
    log_info "Instalando SDKMAN..."
    
    export SDKMAN_DIR="$HOME/.sdkman"
    curl -s "$SDKMAN_URL" | bash 2>&1 | tee -a "$LOG_FILE"
    
    # Registrar para rollback
    echo "rm -rf $SDKMAN_DIR" >> "$ROLLBACK_LOG"
    
    # Carregar SDKMAN
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    
    mark_installed "sdkman" "$(cat "$SDKMAN_DIR/var/version")"
    log_success "SDKMAN instalado"
}

configure_sdkman_zsh() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "sdkman-init.sh" "$zshrc" 2>/dev/null; then
        log_info "SDKMAN já configurado no .zshrc"
        return 0
    fi
    
    log_info "Configurando SDKMAN no .zshrc..."
    
    backup_file "$zshrc"
    
    cat >> "$zshrc" << 'EOF'

# ==========================================
# SDKMAN Configuration
# ==========================================
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

EOF
    
    mark_installed "sdkman_configured" "yes"
}

install_java() {
    # Carregar SDKMAN
    export SDKMAN_DIR="$HOME/.sdkman"
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    
    if sdk list java | grep -q "installed.*$JAVA_VERSION"; then
        log_info "Java $JAVA_VERSION já instalado"
        mark_installed "java" "$JAVA_VERSION"
        return 0
    fi
    
    log_info "Instalando Java $JAVA_VERSION..."
    
    # Instalar de forma não-interativa
    sdk install java "$JAVA_VERSION" < /dev/null 2>&1 | tee -a "$LOG_FILE"
    
    # Definir como padrão
    sdk default java "$JAVA_VERSION" 2>&1 | tee -a "$LOG_FILE"
    
    mark_installed "java" "$JAVA_VERSION"
    log_success "Java instalado: $JAVA_VERSION"
}

configure_java_home() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "JAVA_HOME" "$zshrc" 2>/dev/null && [[ ! $(grep "JAVA_HOME" "$zshrc") =~ ^# ]]; then
        log_info "JAVA_HOME já configurado"
        return 0
    fi
    
    log_info "Configurando JAVA_HOME..."
    
    cat >> "$zshrc" << 'EOF'

# Java Configuration
export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
export PATH="$JAVA_HOME/bin:$PATH"

EOF
    
    mark_installed "java_home_configured" "yes"
}

install_maven() {
    # Carregar SDKMAN
    export SDKMAN_DIR="$HOME/.sdkman"
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    
    if command_exists mvn; then
        local version
        version=$(mvn -v | head -n1 | cut -d' ' -f3)
        log_info "Maven já instalado: $version"
        mark_installed "maven" "$version"
        return 0
    fi
    
    log_info "Instalando Maven $MAVEN_VERSION..."
    
    sdk install maven "$MAVEN_VERSION" < /dev/null 2>&1 | tee -a "$LOG_FILE"
    
    local version
    version=$(mvn -v | head -n1 | cut -d' ' -f3)
    mark_installed "maven" "$version"
    log_success "Maven instalado: $version"
}

install_gradle() {
    # Carregar SDKMAN
    export SDKMAN_DIR="$HOME/.sdkman"
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    
    if command_exists gradle; then
        local version
        version=$(gradle -v | grep "Gradle" | cut -d' ' -f2)
        log_info "Gradle já instalado: $version"
        mark_installed "gradle" "$version"
        return 0
    fi
    
    log_info "Instalando Gradle $GRADLE_VERSION..."
    
    sdk install gradle "$GRADLE_VERSION" < /dev/null 2>&1 | tee -a "$LOG_FILE"
    
    local version
    version=$(gradle -v | grep "Gradle" | cut -d' ' -f2)
    mark_installed "gradle" "$version"
    log_success "Gradle instalado: $version"
}

show_java_info() {
    # Carregar SDKMAN
    export SDKMAN_DIR="$HOME/.sdkman"
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    
    log_info ""
    log_info "═══════════════════════════════════════════════════"
    log_success "Java Stack instalado com sucesso!"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    echo "Versões instaladas:"
    java -version 2>&1 | head -n3
    echo ""
    mvn -v | head -n1
    gradle -v | grep "Gradle"
    echo ""
    echo "Comandos úteis do SDKMAN:"
    echo "  • sdk list java          - Listar versões Java"
    echo "  • sdk install java X.Y   - Instalar versão específica"
    echo "  • sdk use java X.Y       - Usar versão temporariamente"
    echo "  • sdk default java X.Y   - Definir versão padrão"
    echo "  • sdk current            - Ver versões em uso"
    echo ""
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section "Java + Maven + Gradle (SDKMAN)"
    
    install_prerequisites
    install_sdkman
    configure_sdkman_zsh
    install_java
    configure_java_home
    install_maven
    install_gradle
    show_java_info
    
    mark_installed "$COMPONENT" "$(java -version 2>&1 | head -n1 | cut -d'"' -f2)"
    
    log_success "Java stack configurado"
}

main "$@"
