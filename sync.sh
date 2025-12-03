#!/usr/bin/env bash

# ============================================================================
# 📦 SCRIPT DE BACKUP DE DOTFILES PARA NIXOS - VERSIÓN SIMPLIFICADA
# ============================================================================

set -e  # Solo esto, sin pipefail ni -u por ahora

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

REPO_DIR="$HOME/Dotfiles"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
LOG_FILE="/tmp/dotfiles-backup-${TIMESTAMP//[: ]/-}.log"

# Archivos a respaldar (origen -> categoría/archivo)
declare -A BACKUP_FILES=(
    # Zsh
    ["$HOME/.zshrc"]="zsh/.zshrc"
    ["$HOME/.p10k.zsh"]="zsh/.p10k.zsh"

    # WezTerm
    ["$HOME/.config/wezterm/wezterm.lua"]="wezterm/wezterm.lua"

    # NixOS
    ["/etc/nixos/configuration.nix"]="nixos/configuration.nix"
)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FUNCIONES DE UTILIDAD - VERSIÓN SIMPLIFICADA
# ============================================================================

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}📦 $1${NC}"
}

log_message() {
    local msg="$1"
    echo "[$(date '+%H:%M:%S')] $msg" | tee -a "$LOG_FILE"
}

# ============================================================================
# FUNCIONES PRINCIPALES
# ============================================================================

setup_directories() {
    print_header "CREANDO ESTRUCTURA DE DIRECTORIOS"

    local categories=("zsh" "wezterm" "nixos")

    for category in "${categories[@]}"; do
        local dir="$REPO_DIR/$category"
        if [ ! -d "$dir" ]; then
            echo "Creando directorio: $dir"
            mkdir -p "$dir"
            if [ $? -eq 0 ]; then
                print_success "Directorio creado: $category/"
                log_message "Directorio creado: $dir"
            else
                print_error "Error creando directorio: $category/"
                log_message "ERROR - No se pudo crear: $dir"
                return 1
            fi
        else
            print_info "Directorio ya existe: $category/"
        fi
    done
}

backup_file() {
    local source_file="$1"
    local dest_rel_path="$2"
    local dest_file="$REPO_DIR/$dest_rel_path"

    echo "Procesando: $source_file -> $dest_file"

    # Verificar si el archivo fuente existe
    if [ ! -f "$source_file" ] && [ ! -d "$source_file" ]; then
        print_warning "Archivo no encontrado: $source_file"
        log_message "ADVERTENCIA: Archivo no encontrado - $source_file"
        return 2
    fi

    # Para archivos de sistema (NixOS)
    if [[ "$source_file" == "/etc/nixos/"* ]]; then
        echo "  (Archivo de sistema, usando sudo)"

        # Verificar si hay cambios
        if [ -f "$dest_file" ]; then
            if sudo diff -q "$source_file" "$dest_file" >/dev/null 2>&1; then
                print_success "Sin cambios: $(basename "$source_file")"
                return 0
            fi
        fi

        # Copiar con sudo
        if sudo cp -f "$source_file" "$dest_file" 2>&1; then
            print_success "Respaldado: $(basename "$source_file")"
            log_message "RESPALDADO - $source_file -> $dest_file"
            return 0
        else
            print_error "Error copiando: $(basename "$source_file")"
            log_message "ERROR - No se pudo copiar $source_file"
            return 1
        fi
    else
        # Para archivos de usuario
        if [ -f "$dest_file" ]; then
            if diff -q "$source_file" "$dest_file" >/dev/null 2>&1; then
                print_success "Sin cambios: $(basename "$source_file")"
                return 0
            fi
        fi

        # Crear directorio destino si no existe
        mkdir -p "$(dirname "$dest_file")"

        if cp -f "$source_file" "$dest_file" 2>&1; then
            print_success "Respaldado: $(basename "$source_file")"
            log_message "RESPALDADO - $source_file -> $dest_file"

            # Mostrar diferencias brevemente
            echo "  Cambios:"
            diff --color=always -u "$dest_file.old" "$dest_file" 2>/dev/null | head -5 || echo "    (archivo nuevo)"

            return 0
        else
            print_error "Error copiando: $(basename "$source_file")"
            log_message "ERROR - No se pudo copiar $source_file"
            return 1
        fi
    fi
}

perform_backup() {
    print_header "INICIANDO RESPALDO DE ARCHIVOS"

    local total_files=0
    local successful=0
    local failed=0
    local skipped=0

    echo "Total de archivos a respaldar: ${#BACKUP_FILES[@]}"

    for source_file in "${!BACKUP_FILES[@]}"; do
        dest_path="${BACKUP_FILES[$source_file]}"
        ((total_files++)) || true

        echo -e "\n--- Archivo $total_files de ${#BACKUP_FILES[@]} ---"

        # Depuración: mostrar qué se está procesando
        echo "Origen: $source_file"
        echo "Destino: $dest_path"

        result=$(backup_file "$source_file" "$dest_path")
        case $? in
            0)
                ((successful++)) || true
                echo "Resultado: Éxito"
                ;;
            1)
                ((failed++)) || true
                echo "Resultado: Falló"
                ;;
            2)
                ((skipped++)) || true
                echo "Resultado: Saltado"
                ;;
        esac
    done

    # Resumen
    print_header "RESUMEN DEL RESPALDO"
    echo -e "📊 Total de archivos procesados: $total_files"
    echo -e "${GREEN}✅ Exitosos: $successful${NC}"
    echo -e "${YELLOW}⚠️  Saltados: $skipped${NC}"
    echo -e "${RED}❌ Fallidos: $failed${NC}"

    log_message "Resumen: $successful exitosos, $skipped saltados, $failed fallidos"
}

git_operations() {
    print_header "OPERACIONES GIT"

    cd "$REPO_DIR" || {
        print_error "No se pudo acceder al directorio: $REPO_DIR"
        exit 1
    }

    # Verificar si es un repositorio git
    if [ ! -d ".git" ]; then
        print_warning "No es un repositorio git. Inicializando..."
        git init
        echo "Repositorio git inicializado"
    fi

    # Mostrar estado
    print_info "Estado del repositorio:"
    git status --short 2>&1 | tee -a "$LOG_FILE"

    # Verificar si hay cambios
    changes=$(git status --porcelain)
    if [ -z "$changes" ]; then
        print_success "No hay cambios para commit"
        log_message "Sin cambios para commit"
        return 0
    fi

    # Preguntar por mensaje de commit
    local commit_msg
    echo -e "\n${YELLOW}💬 ¿Deseas agregar un mensaje personalizado para el commit?${NC}"
    echo -e "1) Usar mensaje automático: 'Backup: $TIMESTAMP'"
    echo -e "2) Ingresar mensaje personalizado"
    echo -ne "\nSelecciona (1/2): "

    read -r choice
    case $choice in
        2)
            echo -ne "\n📝 Ingresa el mensaje de commit: "
            read -r commit_msg
            if [ -z "$commit_msg" ]; then
                commit_msg="Backup: $TIMESTAMP"
                print_warning "Mensaje vacío, usando automático"
            fi
            ;;
        *)
            commit_msg="Backup: $TIMESTAMP"
            print_info "Usando mensaje automático"
            ;;
    esac

    # Realizar commit
    print_info "Realizando commit..."

    if git add . 2>&1 | tee -a "$LOG_FILE"; then
        echo "Archivos agregados al staging"
    fi

    if git commit -m "$commit_msg" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Commit realizado: $commit_msg"
        log_message "COMMIT - $commit_msg"
    else
        print_error "Error al hacer commit"
        log_message "ERROR - Fallo en commit"
        return 1
    fi

    # Intentar push si hay remote configurado
    if git remote | grep -q origin; then
        print_info "Subiendo cambios a GitHub..."
        if git push origin main 2>&1 | tee -a "$LOG_FILE"; then
            print_success "Cambios subidos exitosamente"
            log_message "PUSH - Exitoso"
        else
            print_warning "No se pudo subir a GitHub"
            echo "Intentando crear rama main..."
            git branch -M main 2>&1 | tee -a "$LOG_FILE"
            git push -u origin main 2>&1 | tee -a "$LOG_FILE" || true
        fi
    else
        print_warning "No hay remote 'origin' configurado"
        echo "Para configurar: git remote add origin URL_DEL_REPO"
        log_message "ADVERTENCIA - No hay remote configurado"
    fi
}

show_final_summary() {
    print_header "ESTRUCTURA FINAL DEL REPOSITORIO"

    echo -e "${BLUE}📁 Contenido de $REPO_DIR:${NC}\n"

    for category in zsh wezterm nixos; do
        local category_dir="$REPO_DIR/$category"
        if [ -d "$category_dir" ]; then
            echo -e "📂 $category/:"
            ls -la "$category_dir/" 2>/dev/null | tail -n +2 | while read line; do
                echo "  $line"
            done
            echo
        fi
    done
}

# ============================================================================
# FUNCIÓN PRINCIPAL - VERSIÓN CON DEPURACIÓN
# ============================================================================

main() {
    echo "=========================================="
    echo "🚀 INICIANDO BACKUP DE DOTFILES"
    echo "=========================================="
    echo "Hora de inicio: $TIMESTAMP"
    echo "Log file: $LOG_FILE"
    echo "Repositorio: $REPO_DIR"
    echo ""

    log_message "=== INICIO DE EJECUCIÓN ==="

    # Crear estructura de directorios
    echo "Paso 1: Creando directorios..."
    setup_directories

    # Realizar backup de archivos
    echo -e "\nPaso 2: Respaldando archivos..."
    perform_backup

    # Operaciones Git
    echo -e "\nPaso 3: Operaciones Git..."
    git_operations

    # Mostrar estructura final
    echo -e "\nPaso 4: Mostrando resumen..."
    show_final_summary

    echo "=========================================="
    echo "🎉 BACKUP COMPLETADO"
    echo "=========================================="
    echo -e "${GREEN}✨ ¡Tus dotfiles están respaldados y versionados!${NC}"
    echo ""
    echo "📋 Log guardado en: $LOG_FILE"
    echo "💾 Repositorio local: $REPO_DIR"

    log_message "=== FIN DE EJECUCIÓN ==="
}

# ============================================================================
# PUNTO DE ENTRADA
# ============================================================================

# Verificar que estamos en bash
if [ -z "$BASH_VERSION" ]; then
    echo "Error: Este script debe ejecutarse con bash"
    exit 1
fi

# Crear archivo de log
touch "$LOG_FILE"

# Ejecutar función principal
main "$@"
