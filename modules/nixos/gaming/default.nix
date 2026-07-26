{ pkgs, ... }:

{
  programs = {
    gamemode.enable = true;
    gamescope.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

  environment.systemPackages = with pkgs; [
    (heroic.override {
      extraPkgs = gamePkgs: [ gamePkgs.gamescope ];
    })
    wineWow64Packages.stable
    wineWow64Packages.waylandFull
  ];
}
