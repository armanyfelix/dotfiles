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

  waywallen = pkgs.appimageTools.wrapType2 rec {
    pname = "waywallen";
    version = "0.4.4";
    src = pkgs.fetchurl {
      url = "https://github.com/waywallen/waywallen/releases/download/v${version}/waywallen-${version}-x86_64.AppImage";
      hash = "sha256-P1KWhxhGYFNUiYcRs8ARN/dUsFg5vWJNaacxYfuch8U=";
    };
    extraInstallCommands = let
      contents = pkgs.appimageTools.extract { inherit pname version src; };
    in ''
      mkdir -p "$out/share"
      cp -r ${contents}/usr/share/{applications,icons} "$out/share/"
    '';
  };
in
{
  xdg.configFile = lib.genAttrs plasmaConfigFiles (name: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/kde/${name}";
  }) // {
    "Kvantum/Utterly-Nord".source = "${pkgs.utterly-nord-plasma}/share/Kvantum/Utterly-Nord";
    # Replace the old desktop autostart; systemd orders startup after Plasma.
    "autostart/waywallen.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Waywallen
      Hidden=true
    '';
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

  home.activation.waywallenDefaultSource = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "${config.xdg.configHome}/waywallen/waywallen.conf" \
      --group DiscoverView --key selectedSourceId wallpaper_engine
  '';

  systemd.user.services.waywallen = {
    Unit = {
      Description = "Waywallen wallpaper daemon";
      Requires = [ "plasma-plasmashell.service" ];
      After = [ "plasma-plasmashell.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${waywallen}/bin/waywallen --no-ui";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "plasma-workspace.target" ];
  };

  home.packages = with pkgs; [
    waywallen
    plasma-panel-colorizer
    kde-rounded-corners
    plasmusic-toolbar
    kdePackages.krohnkite
    kwin-script-geometry-change
    tela-icon-theme
    utterly-nord-plasma
    utterly-round-plasma-style
  ];

  # Explicit links take precedence over manually downloaded copies. Home
  # Manager backs existing files/directories up before replacing them.
  xdg.dataFile = {
    "plasma/wallpapers/org.waywallen.kde".source = pkgs.fetchzip {
      url = "https://github.com/waywallen/waywallen-display/releases/download/v0.4.2/waywallen-kde-0.4.2-x86_64-embed.zip";
      hash = "sha256-hABN/J4o82YjB/szB24vHoeR2NvmLw9ZGrQeWLZyDWI=";
    };
    "waywallen/plugins/org.waywallen.open-wallpaper-engine".source = pkgs.fetchzip {
      url = "https://github.com/waywallen/open-wallpaper-engine/releases/download/v0.3.0/org.waywallen.open-wallpaper-engine-0.3.0-linux-x86_64.zip";
      hash = "sha256-JGZA4ZHf9ZCT5kqG7Pxb/pkbH46TC6nqy7vf+E4jF2c=";
      stripRoot = false;
    };
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
    "plasma/plasmoids/plasmusic-toolbar".source =
      "${pkgs.plasmusic-toolbar}/share/plasma/plasmoids/plasmusic-toolbar";
    "plasma/plasmoids/luisbocanegra.panel.colorizer".source =
      "${pkgs.plasma-panel-colorizer}/share/plasma/plasmoids/luisbocanegra.panel.colorizer";
    "color-schemes/Layan.colors".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/local/share/color-schemes/Layan.colors";
    "color-schemes/LayanLight.colors".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/local/share/color-schemes/LayanLight.colors";
  };
}
