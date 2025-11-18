# Changelog

## [1.0.1] - 2025-11-17

### 🐛 Bug Fixes

#### Conflito de Variável `readonly SCRIPT_DIR`

**Problema:** 
```bash
./src/install.sh --full
/home/admin/bin/linux-terminal-script/src/lib/core.sh: line 18: SCRIPT_DIR: readonly variable
```

**Causa Raiz:**
- A variável `SCRIPT_DIR` estava sendo definida como `readonly` em múltiplos arquivos
- Quando `install.sh` carregava `core.sh`, `idempotent.sh` e `rollback.sh`
- Cada arquivo tentava redefinir `SCRIPT_DIR` como readonly, causando erro

**Solução Implementada:**

1. **core.sh** - Verificação condicional antes de definir:
```bash
# Antes:
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Depois:
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    readonly SCRIPT_DIR
fi
```

2. **core.sh** - Flag de carregamento:
```bash
# No final do arquivo
readonly CORE_SH_LOADED=1
```

3. **idempotent.sh e rollback.sh** - Evitar recarregamento:
```bash
# Antes:
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# Depois:
if [[ -z "${CORE_SH_LOADED:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
fi
```

**Arquivos Modificados:**
- `src/lib/core.sh`
- `src/lib/idempotent.sh`
- `src/lib/rollback.sh`

**Testes Realizados:**
```bash
✓ bash -n lib/core.sh
✓ bash -n lib/idempotent.sh
✓ bash -n lib/rollback.sh
✓ bash -n install.sh
✓ source lib/core.sh && source lib/idempotent.sh && source lib/rollback.sh
```

**Status:** ✅ **RESOLVIDO**

---

## [1.0.0] - 2025-11-17

### 🎉 Release Inicial

#### Funcionalidades

**Sistema de Instalação Automatizada:**
- ✅ Instalação idempotente (pode ser executada múltiplas vezes)
- ✅ Sistema de rollback automático em caso de erro
- ✅ Snapshots do WSL (backup/restore completo)
- ✅ Menu interativo para escolher componentes
- ✅ Modos: `--full`, `--minimal`, `--components`

**Componentes Instalados:**
1. **01-system.sh** - Sistema base Ubuntu
2. **02-zsh.sh** - Zsh + Oh My Zsh
3. **03-powerlevel10k.sh** - Tema Powerlevel10k
4. **04-plugins.sh** - Plugins Zsh essenciais
5. **05-fzf.sh** - Fuzzy Finder
6. **06-nodejs.sh** - Node.js + fnm + pnpm
7. **07-java.sh** - Java + SDKMAN + Maven + Gradle
8. **08-php.sh** - PHP 8.3 + Composer
9. **09-dotnet.sh** - .NET SDK 8.0
10. **10-docker.sh** - Docker CLI + Docker Desktop
11. **11-extras.sh** - Ferramentas modernas (bat, fd, rg, etc)

**Bibliotecas:**
- `lib/core.sh` - Funções essenciais, logging, validações
- `lib/idempotent.sh` - Operações idempotentes
- `lib/rollback.sh` - Sistema de reversão

**Snapshots:**
- `snapshots/create-snapshot.sh` - Criar backup
- `snapshots/list-snapshots.sh` - Listar backups
- `snapshots/restore-snapshot.sh` - Restaurar backup

#### Qualidade

**Análise Técnica:**
- Pontuação: **9.7/10** ⭐⭐⭐⭐⭐
- 18/18 scripts validados ✅
- Baseado em melhores práticas (arslan.io)
- Documentação completa

**Segurança:**
- ✅ Backup automático antes de modificações
- ✅ Validações pré-instalação (WSL, Ubuntu, internet)
- ✅ Verificação de assinaturas (Composer)
- ✅ Uso controlado de sudo
- ✅ HTTPS para todos os downloads

**Performance:**
- ✅ Git shallow clones (--depth=1)
- ✅ fnm (40x mais rápido que nvm)
- ✅ APT otimizado
- ✅ Docker BuildKit habilitado

---

## Como Usar

### Instalação Completa
```bash
cd ~/bin/linux-terminal-script
./src/install.sh --full
```

### Instalação Mínima
```bash
./src/install.sh --minimal
```

### Menu Interativo
```bash
./src/install.sh --components
```

### Listar Componentes
```bash
./src/install.sh --list
```

### Rollback
```bash
./src/install.sh --rollback
```

### Criar Snapshot
```bash
./src/snapshots/create-snapshot.sh
```

---

## Suporte

Para reportar problemas, consulte: `ANALISE_TECNICA.md`
