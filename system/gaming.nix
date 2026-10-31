{ pkgs, ... }:

{
  programs = {
    gamemode.enable = true;
    nix-ld.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

  environment.systemPackages = with pkgs; [
    wineWow64Packages.stable
    wineWow64Packages.waylandFull
  ];
}
