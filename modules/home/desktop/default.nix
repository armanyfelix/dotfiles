{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [ ./niri ];

  home.packages = with pkgs; [
    appflowy
    brave
    obsidian
    protonplus
    signal-desktop
    vlc
    zed-editor
    inputs.zen-browser.packages.${system}.default
    inputs.noctalia.packages.${system}.default
    inputs.zennotes.packages.${system}.default
  ];
}
