{ ... }:

{
  imports = [
    ../../home/desktop.nix
    ../../home/terminal.nix
  ];
  home = {
    username = "armanix";
    homeDirectory = "/home/armanix";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
