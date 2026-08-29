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

  glassyMusicSrc = pkgs.fetchurl {
    url = "https://github.com/NanKillBro/glassy-music-nankill/releases/download/v3.12.10-beta/Glassy-Music-3.12.10-beta.AppImage";
    hash = "sha256-9JZicfK8ofcA9w7G+9UgULdhVABZ0UezIp/1M7e3cXU=";
  };

  glassyMusicContents = pkgs.appimageTools.extractType2 {
    pname = "glassy-music";
    version = "3.12.10-beta";
    src = glassyMusicSrc;
  };

  glassyMusic = pkgs.appimageTools.wrapType2 {
    pname = "glassy-music";
    version = "3.12.10-beta";
    src = glassyMusicSrc;
    extraPkgs = pkgs: [
      pkgs.libglvnd
      pkgs.libnotify
      pkgs.nss
      pkgs.alsa-lib
      pkgs.at-spi2-atk
      pkgs.gtk3
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
    glassyMusic
  ];

  services.kdeconnect.enable = true;

  xdg.desktopEntries.waywallen = {
    name = "Waywallen";
    comment = "Dynamic wallpaper manager";
    exec = "waywallen";
    icon = "org.waywallen.waywallen";
    terminal = false;
    categories = [ "Utility" "Settings" ];
  };

  xdg.desktopEntries.glassy-music = {
    name = "Glassy Music";
    comment = "Music player";
    exec = "glassy-music";
    icon = "glassy-music-nankill-mod";
    terminal = false;
    categories = [ "AudioVideo" "Audio" "Player" ];
  };

  xdg.dataFile."icons/hicolor/512x512/apps/glassy-music-nankill-mod.png".source =
    "${glassyMusicContents}/usr/share/icons/hicolor/512x512/apps/glassy-music-nankill-mod.png";

  xdg.dataFile."icons/hicolor/scalable/apps/org.waywallen.waywallen.svg".source =
    "${waywallenContents}/usr/share/icons/hicolor/scalable/apps/org.waywallen.waywallen.svg";
}
