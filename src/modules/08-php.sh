#!/bin/bash
#=============================================================================
# 08-php.sh - Instalação de PHP 8.3 + Composer e extensões
#=============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/idempotent.sh"

readonly COMPONENT="php"
readonly PHP_VERSION="${PHP_VERSION:-8.3}"
readonly COMPOSER_URL="https://getcomposer.org/installer"

#=============================================================================
# Extensões PHP
#=============================================================================

readonly PHP_EXTENSIONS=(
    "php${PHP_VERSION}-cli"
    "php${PHP_VERSION}-curl"
    "php${PHP_VERSION}-mbstring"
    "php${PHP_VERSION}-xml"
    "php${PHP_VERSION}-zip"
    "php${PHP_VERSION}-mysql"
    "php${PHP_VERSION}-pgsql"
    "php${PHP_VERSION}-sqlite3"
    "php${PHP_VERSION}-gd"
    "php${PHP_VERSION}-bcmath"
    "php${PHP_VERSION}-intl"
    "php${PHP_VERSION}-redis"
    "php${PHP_VERSION}-xdebug"
)

#=============================================================================
# Funções
#=============================================================================

add_php_repository() {
    if is_installed "${COMPONENT}_repo_added"; then
        log_info "Repositório PHP já adicionado"
        return 0
    fi
    
    log_info "Adicionando repositório Ondrej PHP..."
    
    apt_install software-properties-common
    
    sudo add-apt-repository ppa:ondrej/php -y 2>&1 | tee -a "$LOG_FILE"
    sudo apt-get update 2>&1 | tee -a "$LOG_FILE"
    
    mark_installed "${COMPONENT}_repo_added" "yes"
}

install_php() {
    if command_exists php; then
        local version
        version=$(php -v | head -n1 | cut -d' ' -f2)
        log_info "PHP já instalado: $version"
        mark_installed "php_binary" "$version"
        
        # Verificar se é a versão correta
        if [[ ! "$version" =~ ^$PHP_VERSION ]]; then
            log_warning "Versão instalada ($version) difere da desejada ($PHP_VERSION)"
            if confirm "Instalar PHP $PHP_VERSION?"; then
                : # Continua a instalação
            else
                return 0
            fi
        else
            return 0
        fi
    fi
    
    log_info "Instalando PHP $PHP_VERSION e extensões..."
    apt_install "${PHP_EXTENSIONS[@]}"
    
    local version
    version=$(php -v | head -n1 | cut -d' ' -f2)
    mark_installed "php_binary" "$version"
    log_success "PHP instalado: $version"
}

configure_php_cli() {
    local php_ini="/etc/php/${PHP_VERSION}/cli/php.ini"
    
    if is_installed "${COMPONENT}_configured"; then
        log_info "PHP CLI já configurado"
        return 0
    fi
    
    if [[ ! -f "$php_ini" ]]; then
        log_warning "php.ini não encontrado: $php_ini"
        return 0
    fi
    
    log_info "Otimizando configurações PHP CLI..."
    
    backup_file "$php_ini"
    
    # Aplicar configurações recomendadas
    sudo sed -i 's/memory_limit = .*/memory_limit = 512M/' "$php_ini"
    sudo sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$php_ini"
    sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 100M/' "$php_ini"
    sudo sed -i 's/post_max_size = .*/post_max_size = 100M/' "$php_ini"
    
    mark_installed "${COMPONENT}_configured" "yes"
    log_success "PHP CLI configurado"
}

install_composer() {
    if command_exists composer; then
        local version
        version=$(composer --version --no-ansi | cut -d' ' -f3)
        log_info "Composer já instalado: $version"
        mark_installed "composer" "$version"
        return 0
    fi
    
    log_info "Instalando Composer..."
    
    # Download do instalador
    curl -sS "$COMPOSER_URL" -o /tmp/composer-setup.php 2>&1 | tee -a "$LOG_FILE"
    
    # Verificar hash (segurança)
    local expected_signature
    expected_signature=$(curl -sS https://composer.github.io/installer.sig)
    local actual_signature
    actual_signature=$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")
    
    if [[ "$expected_signature" != "$actual_signature" ]]; then
        log_error "Assinatura do Composer inválida!"
        rm /tmp/composer-setup.php
        return 1
    fi
    
    # Instalar globalmente
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer 2>&1 | tee -a "$LOG_FILE"
    rm /tmp/composer-setup.php
    
    # Registrar para rollback
    echo "sudo rm -f /usr/local/bin/composer" >> "$ROLLBACK_LOG"
    
    local version
    version=$(composer --version --no-ansi | cut -d' ' -f3)
    mark_installed "composer" "$version"
    log_success "Composer instalado: $version"
}

configure_composer_path() {
    local zshrc="$HOME/.zshrc"
    
    if grep -q "composer/vendor/bin" "$zshrc" 2>/dev/null; then
        log_info "PATH do Composer já configurado"
        return 0
    fi
    
    log_info "Adicionando Composer global ao PATH..."
    
    append_once "$zshrc" \
        'export PATH="$HOME/.composer/vendor/bin:$HOME/.config/composer/vendor/bin:$PATH"' \
        "composer/vendor/bin"
}

install_global_tools() {
    if ! command_exists composer; then
        log_warning "Composer não disponível, pulando ferramentas globais"
        return 0
    fi
    
    if is_installed "${COMPONENT}_global_tools"; then
        log_info "Ferramentas globais já instaladas"
        return 0
    fi
    
    log_info "Instalando ferramentas globais do PHP..."
    
    # PHPUnit
    composer global require phpunit/phpunit --quiet 2>&1 | tee -a "$LOG_FILE" || log_warning "Falha ao instalar PHPUnit"
    
    # PHP CS Fixer
    composer global require friendsofphp/php-cs-fixer --quiet 2>&1 | tee -a "$LOG_FILE" || log_warning "Falha ao instalar PHP CS Fixer"
    
    # PHP CodeSniffer
    composer global require squizlabs/php_codesniffer --quiet 2>&1 | tee -a "$LOG_FILE" || log_warning "Falha ao instalar PHP CodeSniffer"
    
    mark_installed "${COMPONENT}_global_tools" "yes"
    log_success "Ferramentas globais instaladas"
}

show_php_info() {
    log_info ""
    log_info "═══════════════════════════════════════════════════"
    log_success "PHP Stack instalado com sucesso!"
    log_info "═══════════════════════════════════════════════════"
    echo ""
    php -v | head -n1
    composer --version --no-ansi
    echo ""
    echo "Extensões instaladas:"
    php -m | grep -E "curl|mbstring|xml|zip|mysql|pgsql|gd|redis|xdebug" | sed 's/^/  • /'
    echo ""
    echo "Ferramentas globais instaladas:"
    command -v phpunit >/dev/null && echo "  • PHPUnit"
    command -v php-cs-fixer >/dev/null && echo "  • PHP CS Fixer"
    command -v phpcs >/dev/null && echo "  • PHP CodeSniffer"
    echo ""
}

#=============================================================================
# Main
#=============================================================================

main() {
    log_section "PHP $PHP_VERSION + Composer"
    
    add_php_repository
    install_php
    configure_php_cli
    install_composer
    configure_composer_path
    install_global_tools
    show_php_info
    
    mark_installed "$COMPONENT" "$(php -v | head -n1 | cut -d' ' -f2)"
    
    log_success "PHP stack configurado"
}

main "$@"
