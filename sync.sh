#!/bin/sh
# Sincroniza TODAS tus configuraciones

set -e  # Detiene el script si hay error

echo "🚀 Sincronizando dotfiles..."

# --- CONFIGURACIÓN NIXOS ---
echo "📦 Copiando configuración NixOS..."
sudo cp -r /etc/nixos/* ~/Repos/dotfiles/nixos/ 2>/dev/null || true

# --- CONFIGURACIONES DE USUARIO ---
echo "🏠 Copiando configuraciones de usuario..."

# Zsh
cp ~/.zshrc ~/Repos/dotfiles/home/ 2>/dev/null || true

# Configuraciones comunes
mkdir -p ~/Repos/dotfiles/home/.config
cp -r ~/.config/nvim ~/Repos/dotfiles/home/.config/ 2>/dev/null || true
cp -r ~/.config/kitty ~/Repos/dotfiles/home/.config/ 2>/dev/null || true
# cp -r ~/.config/i3 ~/Repos/dotfiles/home/.config/ 2>/dev/null || true
# cp -r ~/.config/polybar ~/Repos/dotfiles/home/.config/ 2>/dev/null || true

# Scripts personales
mkdir -p ~/Repos/dotfiles/home/scripts
cp -r ~/scripts/* ~/dotfiles/home/scripts/ 2>/dev/null || true

# --- SUBIR A GIT ---
cd ~/Repos/dotfiles
git add .
git commit -m "Update: $(date '+%Y-%m-%d %H:%M:%S')"
git push

echo "✅ ¡Todo sincronizado en GitHub!"
