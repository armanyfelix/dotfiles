{ pkgs, inputs, ... }:

{
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
  ];
}
