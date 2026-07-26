{
  description = "NixOS not from scratch";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #zed = {
    #  url = "github:zed-industries/zed";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, zen-browser, noctalia, ... } @inputs: {
    nixpkgs.overlays = [
      (final: prev: {
	zed-editor = inputs.zed.packages.${prev.system}.default;
      })
    ];
    nixosConfigurations.armanix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
          {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };
                users.lafv = ./home.nix;
              };
          }
      ];
    };
  };
}
