{
  imports = [ ../../profiles/home/personal.nix ];

  home = {
    username = "lafv";
    homeDirectory = "/home/lafv";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
