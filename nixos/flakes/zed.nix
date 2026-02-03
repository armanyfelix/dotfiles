{
  inputs.zed.url = "github:zed-industries/zed";

  outputs =
    {
      self,
      nixpkgs,
      zed,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.zed-latest = zed.packages.${system}.default;
    };
}
