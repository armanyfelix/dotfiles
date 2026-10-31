{ pkgs, inputs, ... }:

let
  zenPackages = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system};
  zenBrowser = zenPackages.default.override {
    zen-browser-unwrapped = zenPackages.zen-browser-unwrapped.override (
      # Work around the flake's stale hash for this release only.
      # Verified against the digest published on the official GitHub release.
      pkgs.lib.optionalAttrs
        (pkgs.stdenv.hostPlatform.system == "x86_64-linux" && zenPackages.default.version == "1.23.3b")
        { hash = "sha256-uyBF0+IWVNQP6EElAJLurf0sH8gx7vtQkiJ3PIvcoUk="; }
    );
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
    zenBrowser
    inputs.zennotes.packages.${pkgs.stdenv.hostPlatform.system}.default
    zed-editor
    appflowy
    brave
    anytype
    signal-desktop
    glassyMusic
    monero-gui
  ];

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
}
