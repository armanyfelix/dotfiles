{ pkgs, inputs, ... }:

let
  waywallenSrc = pkgs.fetchurl {
    url = "https://github.com/waywallen/waywallen/releases/download/v0.3.5/waywallen-0.3.5-x86_64.AppImage";
    hash = "sha256-s1RnL7/mwh+mHJgBGTTBUece8aTCyQUuXK4bPACpMcc=";
  };

  waywallenContents = pkgs.appimageTools.extractType2 {
    pname = "waywallen";
    version = "0.3.5";
    src = waywallenSrc;
  };

  waywallen = pkgs.appimageTools.wrapType2 {
    pname = "waywallen";
    version = "0.3.5";
    src = waywallenSrc;
    extraPkgs = pkgs: [
      pkgs.libglvnd
      pkgs.vulkan-loader
    ];
  };
in
{

  home.packages = with pkgs; [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.zennotes.packages.${pkgs.stdenv.hostPlatform.system}.default
    zed-editor
    appflowy
    brave
    anytype
    signal-desktop
    waywallen
  ];

  xdg.desktopEntries.waywallen = {
    name = "Waywallen";
    comment = "Dynamic wallpaper manager";
    exec = "waywallen";
    icon = "org.waywallen.waywallen";
    terminal = false;
    categories = [ "Utility" "Settings" ];
  };

  xdg.dataFile."icons/hicolor/scalable/apps/org.waywallen.waywallen.svg".source =
    "${waywallenContents}/usr/share/icons/hicolor/scalable/apps/org.waywallen.waywallen.svg";
}
