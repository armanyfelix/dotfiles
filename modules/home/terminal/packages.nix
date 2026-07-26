{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    btop
    cmatrix
    fastfetch
    pay-respects
    tree
    wget
    zoxide
  ];
}
