{ config, dotfilesDir, inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in

{
  # Keep Codex settings writable so the CLI can update trusted hook state.
  home.file.".codex/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/codex/config.toml";

  home.packages = with pkgs; [
    # Control de versiones
    git

    # Build
    gnumake

    # Node.js
    nodejs_26
    pnpm
    bun

    # Rust
    cargo

    # AI assistants from dedicated, fast-moving flakes.
    inputs.claude-code-nix.packages.${system}.default
    inputs.codex-cli-nix.packages.${system}.default
  ];
}
