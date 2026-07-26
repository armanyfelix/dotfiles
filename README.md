# Dotfiles

Configuración personal para NixOS y Home Manager sobre Fedora.

## Estructura

- `hosts/`: diferencias de cada computadora.
- `profiles/`: conjuntos de módulos para cada tipo de máquina.
- `modules/home/`: aplicaciones y configuración portable con Home Manager.
- `modules/nixos/`: servicios y configuración exclusiva de NixOS.

Las aplicaciones conservan sus formatos nativos (Lua, TOML, KDL y Zsh). Home
Manager crea enlaces editables hacia este repositorio mediante
`mkOutOfStoreSymlink`.

## Aplicar configuraciones

En la computadora personal NixOS:

```sh
sudo nixos-rebuild switch --flake path:$PWD#armanix
```

En la computadora Fedora:

```sh
home-manager switch --flake .#lafv@work-fedora
```

El repositorio debe estar clonado en `~/Dotfiles` para que los enlaces editables
coincidan con `dotfilesDir` definido en `flake.nix`.

Cada host NixOS mantiene un `hardware-configuration.nix` local dentro de su
directorio en `hosts/`. El archivo está ignorado por Git. Los comandos usan un
flake `path:` para incluir este archivo local aunque no forme parte del repositorio.
