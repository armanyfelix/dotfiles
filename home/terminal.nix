{ pkgs, inputs, config, dotfilesDir, ... }:

{
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/nvim";

  home.packages = with pkgs; [
    wezterm
    btop
    cmatrix
    fastfetch
    pay-respects
    starship
    wget
    wl-clipboard
    zoxide
    # bat
    curl
    # fd
    # fzf
    git
    # jq
    # ripgrep
    eza
    # unzip
    neovim
    claude-code
    codex
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    nodejs_26
    pnpm
    bun
    cargo
  ];
}
