{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    btop
    cmatrix
    fastfetch
    pay-respects
    starship
    tree
    wget
    wl-clipboard
    zoxide
  ];
}
