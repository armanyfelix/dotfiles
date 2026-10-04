{ config, pkgs, lib, ... }:

{
  systemd.user.services.paperclip = {
    Unit.Description = "Paperclip";

    Service = {
      Type = "simple";
      WorkingDirectory = config.home.homeDirectory;
      ExecStart = "${pkgs.nodejs_26}/bin/npx --yes paperclipai@latest run";
      Environment = [
        "PAPERCLIP_NO_BROWSER=1"
        "PATH=${lib.makeBinPath [ pkgs.nodejs_26 pkgs.git pkgs.coreutils ]}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };

  xdg.desktopEntries.paperclip = {
    name = "Paperclip";
    comment = "Administrar agentes de IA";
    exec = "${pkgs.xdg-utils}/bin/xdg-open http://localhost:3100";
    icon = "applications-office";
    terminal = false;
    categories = [ "Office" ];
  };
}
