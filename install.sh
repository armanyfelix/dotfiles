#!/usr/bin/env bash
# install.sh - Instala dotfiles creando symlinks y copiando configuraciones

set -e

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

readonly REPO="$HOME/Dotfiles"
readonly BACKUP_DIR="$REPO/backup/$(date +%Y%m%d_%H%M%S)"
readonly LOG_FILE="/tmp/dotfiles-install-$(date +%s).log"

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Archivos a enlazar: origen -> destino
declare -A SYMLINKS=(
    ["$REPO/zsh/.zshrc"]="$HOME/.zshrc"
    ["$REPO/zsh/.p10k.zsh"]="$HOME/.p10k.zsh"
    ["$REPO/wezterm/wezterm.lua"]="$HOME/.config/wezterm/wezterm.lua"
    ["$REPO/nixos/configuration.nix"]="/etc/nixos/configuration.nix"
)

# ============================================================================
# FUNCIONES UTILITARIAS
# ============================================================================

print_header() {
    echo -e "\n${BLUE}══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}📦 $1${NC}"; }

log_message() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ============================================================================
# FUNCIONES PRINCIPALES
# ============================================================================

backup_existing() {
    local target="$1"

    if [[ -e "$target" || -L "$target" ]]; then
        # Si ya es un symlink al origen correcto, no hacer nada
        if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$2")" ]]; then
            return 0
        fi

        # Crear backup
        local backup_path="$BACKUP_DIR/$(basename "$target")"
        mkdir -p "$BACKUP_DIR"

        if mv "$target" "$backup_path" 2>/dev/null; then
            print_success "Backup creado: $(basename "$target")"
            log_message "BACKUP: $target → $backup_path"
            return 0
        else
            print_warning "No se pudo hacer backup de: $(basename "$target")"
            return 1
        fi
    fi
    return 0
}

create_symlink() {
    local source="$1"
    local target="$2"

    print_info "Instalando: $(basename "$source")"

    # Verificar que el origen existe
    if [[ ! -f "$source" ]]; then
        print_warning "Origen no encontrado: $source"
        log_message "ERROR: Origen no encontrado - $source"
        return 1
    fi

    # Crear directorio padre del destino si no existe
    mkdir -p "$(dirname "$target")"

    # Hacer backup si existe
    backup_existing "$target" "$source"

    # Crear symlink
    if [[ "$target" == "/etc/nixos/"* ]]; then
        if sudo ln -sf "$source" "$target"; then
            sudo chmod 644 "$target" 2>/dev/null || true
            print_success "Symlink de sistema creado: $name"
            return 0
        else
            print_error "Error creando symlink de sistema: $name"
            return 1
        fi
    else
        if ln -sf "$source" "$target"; then
            print_success "Enlace creado: $(basename "$target")"
            log_message "SYMLINK: $target → $source"
            return 0
        else
            print_error "Error creando enlace: $(basename "$target")"
            log_message "ERROR: Fallo al crear symlink - $target"
            return 1
        fi
    fi
}

verify_installation() {
    print_header "VERIFICACIÓN"

    local all_good=true

    echo -e "${BLUE}🔍 Verificando symlinks:${NC}"

    for source in "${!SYMLINKS[@]}"; do
        local target="${SYMLINKS[$source]}"

        if [[ -L "$target" ]]; then
            local actual_source="$(readlink -f "$target")"
            local expected_source="$(readlink -f "$source")"

            if [[ "$actual_source" == "$expected_source" ]]; then
                echo -e "  ${GREEN}✓ $(basename "$target")${NC}"
            else
                echo -e "  ${RED}✗ $(basename "$target") (enlace incorrecto)${NC}"
                all_good=false
            fi
        elif [[ -f "$target" ]]; then
            echo -e "  ${YELLOW}⚠ $(basename "$target") (archivo regular, no symlink)${NC}"
            all_good=false
        else
            echo -e "  ${RED}✗ $(basename "$target") (no existe)${NC}"
            all_good=false
        fi
    done

    echo
    echo -e "${BLUE}📋 Archivos en backup:${NC}"
    if [[ -d "$BACKUP_DIR" ]]; then
        find "$BACKUP_DIR" -type f | head -10 | while read file; do
            echo "  📦 $(basename "$file")"
        done
        local count=$(find "$BACKUP_DIR" -type f | wc -l)
        [[ $count -gt 10 ]] && echo "  ... y $((count - 10)) más"
    else
        echo "  Ningún backup creado"
    fi

    if $all_good; then
        echo -e "\n${GREEN}✨ Todos los symlinks están correctamente configurados${NC}"
    else
        echo -e "\n${YELLOW}⚠️  Algunos symlinks necesitan atención${NC}"
    fi
}

# ============================================================================
# FLUJO PRINCIPAL
# ============================================================================

main() {

    print_header "🚀 INSTALACIÓN DE DOTFILES"
    echo -e "Repositorio: $REPO"
    echo -e "Log: $LOG_FILE"
    echo

    log_message "=== INICIO DE INSTALACIÓN ==="

    # Crear symlinks
    print_header "CREANDO SYMLINKS"
    for source in "${!SYMLINKS[@]}"; do
        create_symlink "$source" "${SYMLINKS[$source]}"
    done

    # Verificar instalación
    verify_installation

    # Resumen final
    print_header "🎉 INSTALACIÓN COMPLETADA"
    echo -e "${GREEN}¡Dotfiles instalados exitosamente!${NC}"
    echo
    echo -e "📋 Log detallado: $LOG_FILE"
    [[ -d "$BACKUP_DIR" ]] && echo -e "💾 Backups: $BACKUP_DIR"
    echo
    echo -e "Para aplicar los cambios de Zsh, ejecuta:"
    echo -e "  ${BLUE}source ~/.zshrc${NC}"

    log_message "=== INSTALACIÓN COMPLETADA ==="
}

# Ejecutar
main "$@"
