#!/usr/bin/env bash
# restore.sh - Restaura configuraciones desde live/ (inverso de install.sh)

set -e

REPO="$HOME/Dotfiles"

echo "🔄 Restaurando configuraciones desde live/"

# Restaurar Zsh
if [ -f "$REPO/zsh/.zshrc" ]; then
    cp -f "$REPO/zsh/.zshrc" "$HOME/.zshrc"
    echo "✅ .zshrc restaurado"
fi

if [ -f "$REPO/zsh/.p10k.zsh" ]; then
    cp -f "$REPO/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    echo "✅ .p10k.zsh restaurado"
fi

# Restaurar Wezterm
if [ -f "$REPO/wezterm/wezterm.lua" ]; then
    mkdir -p "$HOME/.config/wezterm"
    cp -f "$REPO/wezterm/wezterm.lua" "$HOME/.config/wezterm/"
    echo "✅ wezterm.lua restaurado"
fi

# Restaurar NixOS
if [ -f "$REPO/nixos/configuration.nix" ]; then
    sudo cp -f "$REPO/nixos/configuration.nix" "/etc/nixos/"
    echo "✅ NixOS configuration restaurada"
fi

echo "✨ Restauración completada"
