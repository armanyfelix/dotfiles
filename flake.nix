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

    codex-cli.url = "github:sadjow/codex-cli-nix";
    zennotes.url = "github:ZenNotes/zennotes";
  };

  outputs = inputs@{ home-manager, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      username = "lafv";
      dotfilesDir = "/home/${username}/Dotfiles";
      specialArgs = { inherit inputs dotfilesDir; };
    in
    {
      nixosConfigurations.armanix = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./hosts/armanix/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = specialArgs;
              users.${username} = ./hosts/armanix/home.nix;
            };
          }
        ];
      };

      homeConfigurations."${username}@work-fedora" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = specialArgs;
          modules = [ ./hosts/work-fedora/home.nix ];
        };
    };
}
