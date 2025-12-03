#!/usr/bin/env bash
# install.sh - Crea enlaces simbólicos desde live/ a ubicaciones reales

set -e

REPO="$HOME/Dotfiles"
BACKUP_DIR="$REPO/backup/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/install-dotfiles.log"

echo "=== Instalación de dotfiles: $(date) ===" | tee -a "$LOG_FILE"

# Crear directorio de backup
mkdir -p "$BACKUP_DIR"

# Función para crear symlink con backup
create_symlink() {
    local src="$1"
    local dst="$2"
    local name="$3"

    echo "🔗 $name:" | tee -a "$LOG_FILE"

    # Si el destino ya existe
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        # Si ya es un symlink al mismo lugar, saltar
        if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
            echo "  ✅ Ya enlazado correctamente" | tee -a "$LOG_FILE"
            return 0
        fi

        # Hacer backup
        mkdir -p "$BACKUP_DIR/$(dirname "$dst")"
        mv "$dst" "$BACKUP_DIR/$dst" 2>/dev/null && \
        echo "  📦 Backup creado" | tee -a "$LOG_FILE"
    fi

    # Crear directorio padre si no existe
    mkdir -p "$(dirname "$dst")"

    # Crear symlink
    if ln -sf "$src" "$dst"; then
        echo "  ✅ Enlace creado: $dst → $src" | tee -a "$LOG_FILE"
        return 0
    else
        echo "  ❌ Error creando enlace" | tee -a "$LOG_FILE"
        return 1
    fi
}

echo "--- Creando enlaces simbólicos ---" | tee -a "$LOG_FILE"

# Zsh
create_symlink "$REPO/zsh/.zshrc" "$HOME/.zshrc" "Zsh config"
create_symlink "$REPO/zsh/.p10k.zsh" "$HOME/.p10k.zsh" "Powerlevel10k"

# Wezterm
create_symlink "$REPO/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua" "Wezterm"

echo "--- Configuraciones especiales (sin symlink) ---" | tee -a "$LOG_FILE"

# NixOS (copia directa, no symlink)
if [ -f "$REPO/nixos/configuration.nix" ]; then
    echo "📋 NixOS configuration:" | tee -a "$LOG_FILE"
    sudo cp -f "$REPO/nixos/configuration.nix" "/etc/nixos/" 2>&1 | tee -a "$LOG_FILE"
    if [ $? -eq 0 ]; then
        echo "✅ NixOS instalado" | tee -a "$LOG_FILE"
    else
        echo "❌ Error instalando NixOS" | tee -a "$LOG_FILE"
    fi
fi

echo "=== Instalación completada ===" | tee -a "$LOG_FILE"

# Mostrar enlaces creados
echo -e "\n🔍 Enlaces creados:"
find "$HOME" -maxdepth 2 -type l -name ".*" -o -name "*.lua" | while read link; do
    if [ -L "$link" ]; then
        echo "  $link → $(readlink "$link")"
    fi
done

echo -e "\n💾 Backups en: $BACKUP_DIR"
