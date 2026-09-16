{ pkgs, lib, config, osConfig, dotfilesDir, ... }:

let
  # Writable links: changes made in System Settings belong to this checkout.
  plasmaConfigFiles = [
    "breezerc"
    "dolphinrc"
    "kactivitymanagerdrc"
    "kactivitymanagerd-statsrc"
    "kcminputrc"
    "kdeglobals"
    "kglobalshortcutsrc"
    "konsolerc"
    "krunnerrc"
    "ksmserverrc"
    "kwinrc"
    "kwinrulesrc"
    "plasma-org.kde.plasma.desktop-appletsrc"
    "plasmanotifyrc"
    "plasmarc"
    "plasmashellrc"
    "powermanagementprofilesrc"
    "Kvantum/kvantum.kvconfig"
  ];

  mkPlasmoid = {
    pname,
    version,
    owner,
    repo,
    rev,
    hash,
    plasmoidId,
    sourceDir ? ".",
  }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;
      src = pkgs.fetchFromGitHub { inherit owner repo rev hash; };
      dontBuild = true;

      installPhase = ''
        mkdir -p "$out/share/plasma/plasmoids/${plasmoidId}"
        cp -r ${sourceDir}/. "$out/share/plasma/plasmoids/${plasmoidId}"
      '';
    };

  runcat = mkPlasmoid {
    pname = "kde-runcat";
    version = "0.4.0";
    owner = "fioncat";
    repo = "kde-runcat";
    rev = "ea4e0cc1ce47e69908b0501d0f9fae66309adb91";
    hash = "sha256-bbBWMDc/pzJQ2Ee0yMYo1waxKrER0Axe+3hiHo83iRA=";
    plasmoidId = "com.github.runcatkde.runcat";
  };

  waywallenKde = pkgs.fetchurl {
    url = "https://github.com/waywallen/waywallen-display/releases/download/v0.3.3/waywallen-kde-0.3.3-x86_64-embed.zip";
    hash = "sha256-0SGuTy/KLSZkts1qb1x3GticUwOI3CQVWyRNhzOuBZ4=";
  };

  waywallenWallpaper = pkgs.stdenvNoCC.mkDerivation {
    pname = "waywallen-kde";
    version = "0.3.3";
    src = waywallenKde;
    nativeBuildInputs = [ pkgs.unzip ];
    sourceRoot = "org.waywallen.kde";
    dontBuild = true;
    # Preserve the upstream embedded plugin exactly as previously installed.
    dontFixup = true;
    installPhase = ''
      mkdir -p "$out/share/plasma/wallpapers/org.waywallen.kde"
      cp -r . "$out/share/plasma/wallpapers/org.waywallen.kde/"
    '';
  };
in
{
  xdg.configFile = lib.genAttrs plasmaConfigFiles (name: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/kde/${name}";
  }) // {
    "Kvantum/Utterly-Nord".source = "${pkgs.utterly-nord-plasma}/share/Kvantum/Utterly-Nord";
  };

  home.activation.checkPlasmaConfig = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    ${lib.concatMapStringsSep "\n" (name: ''
      if [[ ! -f ${lib.escapeShellArg "${dotfilesDir}/config/kde/${name}"} ]]; then
        echo ${lib.escapeShellArg "Missing Plasma configuration: ${dotfilesDir}/config/kde/${name}"} >&2
        exit 1
      fi
    '') plasmaConfigFiles}
  '';

  home.activation.retireCompactPager = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    legacyPager=${lib.escapeShellArg "${config.xdg.dataHome}/plasma/plasmoids/com.github.tilorenz.compact_pager"}
    if [[ -e "$legacyPager" || -L "$legacyPager" ]]; then
      run ${lib.escapeShellArg (toString osConfig.home-manager.backupCommand)} "$legacyPager"
    fi
  '';

  # Explicit links take precedence over manually downloaded copies. Home
  # Manager backs existing files/directories up before replacing them.
  xdg.dataFile = {
    "plasma/wallpapers/org.waywallen.kde".source =
      "${waywallenWallpaper}/share/plasma/wallpapers/org.waywallen.kde";
    "kwin/scripts/krohnkite".source =
      "${pkgs.kdePackages.krohnkite}/share/kwin/scripts/krohnkite";
    "kwin/effects/kwin4_effect_geometry_change".source =
      "${pkgs.kwin-script-geometry-change}/share/kwin/effects/kwin4_effect_geometry_change";
    "plasma/look-and-feel/Utterly-Nord".source =
      "${pkgs.utterly-nord-plasma}/share/plasma/look-and-feel/Utterly-Nord";
    "plasma/desktoptheme/Utterly-Round".source =
      "${pkgs.utterly-round-plasma-style}/share/plasma/desktoptheme/Utterly-Round";
    "aurorae/themes/Utterly-Round-Dark".source =
      "${pkgs.utterly-round-plasma-style}/share/aurorae/themes/Utterly-Round-Dark";
    "aurorae/themes/Utterly-Round-Light-Solid".source =
      "${pkgs.utterly-round-plasma-style}/share/aurorae/themes/Utterly-Round-Light-Solid";
    "plasma/plasmoids/com.github.runcatkde.runcat".source =
      "${runcat}/share/plasma/plasmoids/com.github.runcatkde.runcat";
    "plasma/plasmoids/plasmusic-toolbar".source =
      "${pkgs.plasmusic-toolbar}/share/plasma/plasmoids/plasmusic-toolbar";
    "plasma/plasmoids/luisbocanegra.panel.colorizer".source =
      "${pkgs.plasma-panel-colorizer}/share/plasma/plasmoids/luisbocanegra.panel.colorizer";
    "color-schemes/Layan.colors".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/local/share/color-schemes/Layan.colors";
    "color-schemes/LayanLight.colors".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/local/share/color-schemes/LayanLight.colors";
  };

  home.packages = with pkgs; [
    plasma-panel-colorizer
    kde-rounded-corners
    plasmusic-toolbar
    runcat
    kdePackages.krohnkite
    kwin-script-geometry-change
    tela-icon-theme
    utterly-nord-plasma
    utterly-round-plasma-style
  ];
}
