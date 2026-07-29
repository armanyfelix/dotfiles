{
  imports = [ ../../profiles/home/personal.nix ];

  home = {
    username = "armanix";
    homeDirectory = "/home/armanix";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
