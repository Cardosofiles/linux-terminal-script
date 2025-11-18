#!/bin/bash
#=============================================================================
# idempotent.sh - Wrappers idempotentes para operações comuns
# Baseado em: https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts
#=============================================================================

# Não recarregar core.sh se já foi carregado
if [[ -z "${CORE_SH_LOADED:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
fi

#=============================================================================
# Instalação de Pacotes APT (Idempotente)
#=============================================================================

apt_install() {
    local packages=("$@")
    local to_install=()
    
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -qw "^ii  $pkg"; then
            to_install+=("$pkg")
        else
            log_info "Pacote já instalado: $pkg"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Instalando: ${to_install[*]}"
        sudo apt-get install -y "${to_install[@]}" 2>&1 | tee -a "$LOG_FILE"
        
        # Registra para rollback
        for pkg in "${to_install[@]}"; do
            echo "apt_remove $pkg" >> "$ROLLBACK_LOG"
        done
        
        log_success "Pacotes instalados: ${to_install[*]}"
    else
        log_info "Nenhum pacote novo para instalar"
    fi
}

apt_remove() {
    local pkg="$1"
    if dpkg -l | grep -qw "^ii  $pkg"; then
        sudo apt-get remove -y "$pkg" 2>&1 | tee -a "$LOG_FILE"
        log_info "Removido: $pkg"
    fi
}

#=============================================================================
# Criação de Diretórios (Idempotente)
#=============================================================================

mkdir_safe() {
    local dir="$1"
    mkdir -p "$dir" 2>&1 | tee -a "$LOG_FILE"
    log_info "Diretório assegurado: $dir"
}

#=============================================================================
# Links Simbólicos (Idempotente)
#=============================================================================

ln_safe() {
    local source="$1"
    local target="$2"
    
    # -s: simbólico, -f: force, -n: não seguir links no destino
    ln -sfn "$source" "$target" 2>&1 | tee -a "$LOG_FILE"
    
    # Registra para rollback
    echo "rm -f $target" >> "$ROLLBACK_LOG"
    
    log_info "Link criado: $target -> $source"
}

#=============================================================================
# Append em Arquivo (Idempotente)
#=============================================================================

append_once() {
    local file="$1"
    local content="$2"
    local marker="${3:-$content}"
    
    # Backup antes de modificar
    if [[ -f "$file" ]]; then
        backup_file "$file"
    fi
    
    # Verifica se já existe
    if ! grep -qF "$marker" "$file" 2>/dev/null; then
        echo "$content" >> "$file"
        log_info "Adicionado ao $file"
        
        # Registra para rollback
        echo "sed -i '/$marker/d' $file" >> "$ROLLBACK_LOG"
    else
        log_info "Conteúdo já existe em $file"
    fi
}

#=============================================================================
# Git Clone (Idempotente)
#=============================================================================

git_clone_safe() {
    local repo="$1"
    local destination="$2"
    local depth="${3:-}"
    
    if [[ -d "$destination/.git" ]]; then
        log_info "Repositório já clonado: $destination"
        
        # Atualiza se necessário
        if confirm "Atualizar repositório existente?"; then
            (cd "$destination" && git pull) 2>&1 | tee -a "$LOG_FILE"
            log_success "Repositório atualizado: $destination"
        fi
    else
        local clone_args=()
        [[ -n "$depth" ]] && clone_args+=("--depth=$depth")
        
        git clone "${clone_args[@]}" "$repo" "$destination" 2>&1 | tee -a "$LOG_FILE"
        
        # Registra para rollback
        echo "rm -rf $destination" >> "$ROLLBACK_LOG"
        
        log_success "Repositório clonado: $destination"
    fi
}

#=============================================================================
# Download e Execução de Scripts (Idempotente)
#=============================================================================

download_and_run() {
    local url="$1"
    local check_command="$2"
    local component_name="$3"
    
    if is_installed "$component_name"; then
        log_info "$component_name já instalado"
        return 0
    fi
    
    if command_exists "$check_command"; then
        log_info "$check_command já disponível"
        mark_installed "$component_name"
        return 0
    fi
    
    log_info "Baixando e executando: $url"
    curl -fsSL "$url" | bash 2>&1 | tee -a "$LOG_FILE"
    
    if command_exists "$check_command"; then
        mark_installed "$component_name" "$(command -v "$check_command")"
        log_success "$component_name instalado com sucesso"
    else
        log_error "Falha ao instalar $component_name"
        return 1
    fi
}

#=============================================================================
# Alteração de Shell (Idempotente)
#=============================================================================

change_shell_safe() {
    local new_shell="$1"
    local current_shell
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    
    if [[ "$current_shell" == "$new_shell" ]]; then
        log_info "Shell já configurado: $new_shell"
        return 0
    fi
    
    # Backup shell atual
    echo "$current_shell" > "$STATE_DIR/previous_shell"
    
    chsh -s "$new_shell" 2>&1 | tee -a "$LOG_FILE"
    
    # Registra para rollback
    echo "chsh -s $current_shell" >> "$ROLLBACK_LOG"
    
    log_success "Shell alterado para: $new_shell"
}

#=============================================================================
# Exportar funções
#=============================================================================

export -f apt_install apt_remove mkdir_safe ln_safe append_once
export -f git_clone_safe download_and_run change_shell_safe
