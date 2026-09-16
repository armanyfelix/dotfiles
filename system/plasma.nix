{ lib, pkgs, ... }:

{
  # Keep replaced files outside KDE's theme/widget discovery directories.
  # Unique backups also avoid collisions with a previous activation's backup.
  home-manager.backupCommand = toString (pkgs.writeShellScript "home-manager-backup" ''
    set -euo pipefail
    target="$1"
    case "$target" in
      "$HOME"/*) ;;
      *) echo "Refusing to back up a path outside the user home: $target" >&2; exit 1 ;;
    esac
    relative="''${target#"$HOME"/}"
    backupRoot="''${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/backups"
    ${pkgs.coreutils}/bin/mkdir -p -- "$backupRoot"
    backupDir=$(${pkgs.coreutils}/bin/mktemp -d "$backupRoot/activation-XXXXXXXX")
    ${pkgs.coreutils}/bin/mkdir -p -- "$backupDir/$(${pkgs.coreutils}/bin/dirname -- "$relative")"
    ${pkgs.coreutils}/bin/mv -- "$target" "$backupDir/$relative"
    echo "Backed up $target to $backupDir/$relative"
  '');

  nixpkgs.overlays = [
    (_final: prev: {
      kdePackages = prev.kdePackages.overrideScope (_kfinal: kprev: {
        # KWin 6.7.4 disconnects clients acknowledging removed globals.
        # Backport https://invent.kde.org/plasma/kwin/-/merge_requests/9784
        # Retire this backport when moving beyond the affected release.
        kwin = kprev.kwin.overrideAttrs (old: {
          patches = (old.patches or [ ])
            ++ lib.optionals (old.version == "6.7.4") [
              ./patches/kwin-wl-fixes-v1.patch
              ./patches/kwin-ignore-stale-blur.patch
            ];
        });
      });
    })
  ];
}
