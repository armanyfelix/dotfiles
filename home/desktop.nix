{ pkgs, inputs, ... }:

{

  home.packages = with pkgs; [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.zennotes.packages.${pkgs.stdenv.hostPlatform.system}.default
    zed-editor
    appflowy
    brave
    anytype
    signal-desktop
  ];

  services.flatpak = {
    enable = true;
    packages = [ "org.waywallen.waywallen" ];
    update.auto.enable = true;
  };
}
