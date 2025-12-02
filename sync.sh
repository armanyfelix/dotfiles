#!/usr/bin/env bash

set -e

REPO="$HOME/Repos/dotfiles"
LOG_FILE="/tmp/sync-dotfiles.log"

echo "=== Sincronización iniciada: $(date) ===" | tee -a "$LOG_FILE"

# Crear directorios
for dir in nixos zsh config scripts; do
    mkdir -p "$REPO/$dir"
done

# Función para copiar con log
copy_file() {
    local src="$1"
    local dst="$2"

    if [ -f "$src" ]; then
        if cp -f "$src" "$dst" 2>/dev/null; then
            echo "✅ Copiado: $(basename "$src")" | tee -a "$LOG_FILE"
            return 0
        else
            echo "❌ Error copiando: $(basename "$src")" | tee -a "$LOG_FILE"
            return 1
        fi
    else
        echo "⚠️  No existe: $src" | tee -a "$LOG_FILE"
        return 2
    fi
}

# Copiar archivos
echo "--- Copiando archivos ---" | tee -a "$LOG_FILE"

# NixOS
sudo cp -f /etc/nixos/configuration.nix "$REPO/nixos/" 2>&1 | tee -a "$LOG_FILE"

# Zsh
copy_file "$HOME/.zshrc" "$REPO/zsh/.zshrc"
copy_file "$HOME/.p10k.zsh" "$REPO/zsh/.p10k.zsh"

# Git operations
echo "--- Operaciones Git ---" | tee -a "$LOG_FILE"
cd "$REPO"

# Mostrar cambios
echo "Cambios:" | tee -a "$LOG_FILE"
git status --short | tee -a "$LOG_FILE"

# Commit si hay cambios
if ! git diff --quiet || ! git diff --cached --quiet; then
    git add . | tee -a "$LOG_FILE"
    git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
    git push origin main | tee -a "$LOG_FILE"
    echo "✅ Commit realizado" | tee -a "$LOG_FILE"
else
    echo "📭 Sin cambios" | tee -a "$LOG_FILE"
fi

echo "=== Sincronización completada ===" | tee -a "$LOG_FILE"
