{
  description = "Personal and work system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    zennotes.url = "github:ZenNotes/zennotes";
    herdr.url = "github:herdrdev/herdr";
  };

  outputs = inputs@{ home-manager, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      username = "armanix";
      dotfilesDir = "/home/${username}/Dotfiles";
      specialArgs = { inherit inputs dotfilesDir; };
    in
    {
      nixosConfigurations.ideapad = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./hosts/ideapad/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = specialArgs;
              users.${username} = ./hosts/ideapad/home.nix;
            };
          }
        ];
      };
    };
}
