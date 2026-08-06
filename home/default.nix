{ ... }:

{
  imports = [
    ./packages.nix
    ./terminal.nix
  ];

  programs.home-manager.enable = true;
}
