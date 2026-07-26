{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  programs.git.enable = true;

  home.packages = with pkgs; [
    bun
    nodejs_24
    pnpm
    inputs.codex-cli.packages.${system}.default
  ];
}
