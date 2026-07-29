#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFAULT_REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

HOST_NAME=""
TARGET_ROOT="/mnt"
REPO_DIR="$DEFAULT_REPO_DIR"
USER_NAME="lafv"
ASSUME_YES=false
CHECK_ONLY=false
REGENERATE_HARDWARE=false
SCAN_DIR=""

usage() {
  cat <<'EOF'
Uso:
  sudo ./scripts/install-nixos.sh --host HOST [opciones]

Opciones:
  --host HOST             Host declarado en flake.nix (obligatorio).
  --root RUTA             Raíz del sistema montado (por defecto: /mnt).
  --repo RUTA             Ruta del repositorio (por defecto: detectada).
  --user USUARIO          Usuario propietario de Dotfiles (por defecto: lafv).
  --regenerate-hardware   Regenera hardware-configuration.nix aunque exista.
  --check-only            Genera/verifica, pero no ejecuta nixos-install.
  --yes                   Acepta confirmaciones no destructivas.
  -h, --help              Muestra esta ayuda.

Este script no particiona, formatea ni monta discos.
EOF
}

info() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'Advertencia: %s\n' "$*" >&2
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

confirm() {
  local prompt="$1"
  local answer

  if "$ASSUME_YES"; then
    return 0
  fi

  read -r -p "$prompt [y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

cleanup() {
  if [[ -n "$SCAN_DIR" && -d "$SCAN_DIR" ]]; then
    rm -rf -- "$SCAN_DIR"
  fi
}

trap cleanup EXIT

while (( $# > 0 )); do
  case "$1" in
    --host)
      (( $# >= 2 )) || die "--host necesita un valor"
      HOST_NAME="$2"
      shift 2
      ;;
    --root)
      (( $# >= 2 )) || die "--root necesita un valor"
      TARGET_ROOT="$2"
      shift 2
      ;;
    --repo)
      (( $# >= 2 )) || die "--repo necesita un valor"
      REPO_DIR="$2"
      shift 2
      ;;
    --user)
      (( $# >= 2 )) || die "--user necesita un valor"
      USER_NAME="$2"
      shift 2
      ;;
    --regenerate-hardware)
      REGENERATE_HARDWARE=true
      shift
      ;;
    --check-only)
      CHECK_ONLY=true
      shift
      ;;
    --yes)
      ASSUME_YES=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "opción desconocida: $1"
      ;;
  esac
done

[[ -n "$HOST_NAME" ]] || die "debes indicar --host"
[[ "$HOST_NAME" =~ ^[a-zA-Z0-9._-]+$ ]] || die "nombre de host inválido"
[[ "$USER_NAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "nombre de usuario inválido"
(( EUID == 0 )) || die "ejecuta este script con sudo o como root"

for command_name in nix nixos-generate-config nixos-install mountpoint; do
  command -v "$command_name" >/dev/null 2>&1 ||
    die "no se encontró el comando: $command_name"
done

TARGET_ROOT="$(realpath -e -- "$TARGET_ROOT")" ||
  die "la raíz indicada no existe"
REPO_DIR="$(realpath -e -- "$REPO_DIR")" ||
  die "el repositorio indicado no existe"

[[ -f "$REPO_DIR/flake.nix" ]] || die "no existe $REPO_DIR/flake.nix"
[[ -f "$REPO_DIR/hosts/$HOST_NAME/nixos.nix" ]] ||
  die "el host '$HOST_NAME' no existe en hosts/"
mountpoint -q -- "$TARGET_ROOT" ||
  die "$TARGET_ROOT no es un punto de montaje"

readonly EXPECTED_REPO="$TARGET_ROOT/home/$USER_NAME/Dotfiles"
if [[ "$REPO_DIR" != "$EXPECTED_REPO" ]]; then
  warn "el repositorio no está en su ubicación persistente esperada:"
  warn "  actual:  $REPO_DIR"
  warn "  esperada: $EXPECTED_REPO"
  die "clona o mueve Dotfiles a la ubicación esperada antes de instalar"
fi

readonly HOST_DIR="$REPO_DIR/hosts/$HOST_NAME"
readonly HARDWARE_FILE="$HOST_DIR/hardware-configuration.nix"
readonly FLAKE_URI="path:$REPO_DIR"

info "Host: $HOST_NAME"
info "Sistema montado en: $TARGET_ROOT"
info "Repositorio: $REPO_DIR"

if [[ ! -f "$HARDWARE_FILE" ]] || "$REGENERATE_HARDWARE"; then
  SCAN_DIR="$(mktemp -d -t dotfiles-nixos.XXXXXX)"
  info "Detectando hardware y sistemas de archivos"
  nixos-generate-config --root "$TARGET_ROOT" --dir "$SCAN_DIR"

  [[ -f "$SCAN_DIR/hardware-configuration.nix" ]] ||
    die "nixos-generate-config no produjo hardware-configuration.nix"

  if [[ -f "$HARDWARE_FILE" ]]; then
    if cmp -s -- "$SCAN_DIR/hardware-configuration.nix" "$HARDWARE_FILE"; then
      info "La configuración de hardware no cambió"
    else
      confirm "¿Reemplazar la configuración de hardware existente?" ||
        die "operación cancelada"
      backup_file="${HARDWARE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
      cp -a -- "$HARDWARE_FILE" "$backup_file"
      install -m 0644 -- "$SCAN_DIR/hardware-configuration.nix" "$HARDWARE_FILE"
      info "Respaldo creado: $backup_file"
    fi
  else
    install -m 0644 -- "$SCAN_DIR/hardware-configuration.nix" "$HARDWARE_FILE"
    info "Hardware guardado en: $HARDWARE_FILE"
  fi
else
  info "Usando la configuración de hardware existente"
fi

info "Evaluando la configuración de $HOST_NAME"
nix eval --raw \
  "$FLAKE_URI#nixosConfigurations.${HOST_NAME}.config.system.build.toplevel.drvPath" \
  >/dev/null
info "La configuración evalúa correctamente"

if "$CHECK_ONLY"; then
  info "Verificación terminada; no se instaló el sistema"
  exit 0
fi

printf '\nSe ejecutará:\n  nixos-install --root %q --flake %q\n\n' \
  "$TARGET_ROOT" "$FLAKE_URI#$HOST_NAME"
confirm "¿Continuar con la instalación de NixOS?" || die "instalación cancelada"

nixos-install \
  --root "$TARGET_ROOT" \
  --flake "$FLAKE_URI#$HOST_NAME"

info "Instalación completada"
info "Después de reiniciar, verifica que $USER_NAME sea propietario de ~/Dotfiles"
