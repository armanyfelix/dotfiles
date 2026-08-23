{ pkgs, lib, ... }:

let
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

  compactPager = mkPlasmoid {
    pname = "compact-pager";
    version = "3.12";
    owner = "tilorenz";
    repo = "compact_pager";
    rev = "2b00bbbbb572f7e11b5a5156069665f320d945ac";
    hash = "sha256-i/wgh+HokBckich4gID7gkFQseQXqMo+tGrYpsqshJY=";
    plasmoidId = "com.github.tilorenz.compact_pager";
    sourceDir = "package";
  };

  waywallenKde = pkgs.fetchurl {
    url = "https://github.com/waywallen/waywallen-display/releases/download/v0.3.3/waywallen-kde-0.3.3-x86_64-embed.zip";
    hash = "sha256-0SGuTy/KLSZkts1qb1x3GticUwOI3CQVWyRNhzOuBZ4=";
  };
in
{
  home.packages = with pkgs; [
    plasma-panel-colorizer
    kde-rounded-corners
    plasmusic-toolbar
    runcat
    compactPager
  ];

  home.activation.installWaywallenKde = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! $DRY_RUN_CMD ${pkgs.kdePackages.kpackage}/bin/kpackagetool6 \
      --type Plasma/Wallpaper \
      --upgrade ${waywallenKde}; then
      $DRY_RUN_CMD ${pkgs.kdePackages.kpackage}/bin/kpackagetool6 \
        --type Plasma/Wallpaper \
        --install ${waywallenKde}
    fi
  '';
}
