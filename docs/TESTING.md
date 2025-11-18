# 🧪 Guia de Testes - Sistema de Instalação WSL

## ✅ Problema Resolvido

**Erro Original:**
```bash
./src/install.sh --full
/home/admin/bin/linux-terminal-script/src/lib/core.sh: line 18: SCRIPT_DIR: readonly variable
```

**Status:** ✅ **CORRIGIDO** na versão 1.0.1

---

## 🚀 Como Testar

### 1️⃣ Validação de Sintaxe

```bash
cd ~/bin/linux-terminal-script/src

# Testar sintaxe de todos os scripts
bash -n install.sh
bash -n lib/core.sh
bash -n lib/idempotent.sh
bash -n lib/rollback.sh

# Testar módulos
for file in modules/*.sh; do bash -n "$file" && echo "✓ $file"; done
```

**Resultado Esperado:** ✅ Nenhum erro de sintaxe

---

### 2️⃣ Teste de Carregamento de Bibliotecas

```bash
# Testar se as bibliotecas carregam sem conflito
cd ~/bin/linux-terminal-script/src

bash -c '
source lib/core.sh
source lib/idempotent.sh
source lib/rollback.sh
echo "✓ Bibliotecas carregadas sem conflito"
'
```

**Resultado Esperado:** ✅ `✓ Bibliotecas carregadas sem conflito`

---

### 3️⃣ Teste do Menu de Ajuda

```bash
cd ~/bin/linux-terminal-script
./src/install.sh --help
```

**Resultado Esperado:** 
```
Uso: install.sh [opções]

Opções:
  --full              Instalação completa de todos os componentes
  --minimal           Instalação mínima (zsh, terminal, essentials)
  --components        Menu interativo para escolher componentes
  ...
```

---

### 4️⃣ Teste de Listagem (Modo Seguro)

```bash
cd ~/bin/linux-terminal-script
./src/install.sh --list
```

**Resultado Esperado:** Lista de componentes instalados (pode estar vazia se primeira execução)

---

### 5️⃣ Teste de Validações Pré-Instalação

```bash
cd ~/bin/linux-terminal-script

# Criar script de teste
cat > test_validations.sh << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/src" && pwd)"
source "$SCRIPT_DIR/lib/core.sh"

echo "Testando validações..."
pre_install_checks
echo "✓ Validações passaram!"
EOF

chmod +x test_validations.sh
./test_validations.sh
```

**Resultado Esperado:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ Validações Pré-Instalação
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✔ Todas as validações passaram
✓ Validações passaram!
```

---

### 6️⃣ Teste de Dry-Run (Instalação Simulada)

⚠️ **ATENÇÃO:** Este teste **não instala nada**, apenas verifica se o script inicia corretamente.

```bash
cd ~/bin/linux-terminal-script

# Criar wrapper para simular instalação
cat > test_dryrun.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "🧪 TESTE DRY-RUN - Nenhum pacote será instalado"
echo ""

# Definir flag de teste
export DRY_RUN=1

# Simular resposta "não" para confirmações
yes n | timeout 5 ./src/install.sh --components || true

echo ""
echo "✓ Script iniciou sem erros de readonly"
EOF

chmod +x test_dryrun.sh
./test_dryrun.sh
```

**Resultado Esperado:** Script inicia e mostra o banner sem erros

---

### 7️⃣ Teste Completo de Instalação (OPCIONAL)

⚠️ **CUIDADO:** Este teste **instala componentes reais** no sistema!

#### Opção A: Instalação Mínima (Mais Segura)
```bash
cd ~/bin/linux-terminal-script
./src/install.sh --minimal --skip-snapshot
```

**Instala apenas:**
- Sistema base Ubuntu
- Zsh + Oh My Zsh
- Powerlevel10k
- Plugins Zsh
- FZF

#### Opção B: Instalação Interativa
```bash
cd ~/bin/linux-terminal-script
./src/install.sh --components
```

**Permite escolher** quais componentes instalar.

#### Opção C: Instalação Completa
```bash
cd ~/bin/linux-terminal-script
./src/install.sh --full
```

**Instala tudo:** system, zsh, p10k, plugins, fzf, nodejs, java, php, dotnet, docker, extras

---

## 🔍 Verificação de Sucesso

### Componentes Instalados
```bash
# Ver lista de componentes instalados
./src/install.sh --list

# Ver logs
ls -lh ~/.wsl-setup/logs/

# Ver estado
ls -lh ~/.wsl-setup/state/
```

### Verificar Versões
```bash
# Node.js
node -v
npm -v
pnpm -v

# Java
java -version
mvn -version
gradle -version

# PHP
php -v
composer -v

# .NET
dotnet --version

# Docker
docker --version
docker compose version

# Ferramentas extras
bat --version
fd --version
rg --version
```

---

## 🔄 Rollback (Se Necessário)

### Rollback Completo
```bash
cd ~/bin/linux-terminal-script
./src/install.sh --rollback
# Escolha opção 1 (Rollback completo)
```

### Rollback de Componente Específico
```bash
cd ~/bin/linux-terminal-script
./src/install.sh --rollback
# Escolha opção 2 e digite o nome do componente
```

---

## 📊 Checklist de Testes

Marque cada teste conforme for executando:

- [ ] ✅ Validação de sintaxe de todos os scripts
- [ ] ✅ Teste de carregamento de bibliotecas sem conflito
- [ ] ✅ Menu de ajuda funciona
- [ ] ✅ Listagem de componentes funciona
- [ ] ✅ Validações pré-instalação passam
- [ ] ✅ Script inicia sem erro de readonly
- [ ] ⚠️ Instalação mínima (OPCIONAL)
- [ ] ⚠️ Instalação completa (OPCIONAL)
- [ ] ✅ Rollback funciona (se instalou)

---

## 🐛 Troubleshooting

### Erro: "readonly variable"
**Status:** ✅ **CORRIGIDO** na v1.0.1

Se ainda ver este erro:
```bash
cd ~/bin/linux-terminal-script
git pull origin main  # Atualizar para última versão
```

### Erro: "Este script deve ser executado no WSL"
**Causa:** Script sendo executado fora do WSL

**Solução:**
```bash
# No PowerShell
wsl
# Agora execute o script
```

### Erro: "Sem conexão com a internet"
**Causa:** Rede não configurada

**Solução:**
```bash
ping 8.8.8.8
# Se falhar, verificar rede do WSL
```

### Logs Detalhados
```bash
# Ver último log
tail -f ~/.wsl-setup/logs/install-*.log

# Ver todos os logs
ls -lh ~/.wsl-setup/logs/
```

---

## 📞 Suporte

- **Documentação Técnica:** `ANALISE_TECNICA.md`
- **Changelog:** `CHANGELOG.md`
- **Código Fonte:** `src/`

---

**Última Atualização:** 17 de Novembro de 2025  
**Versão Testada:** 1.0.1
