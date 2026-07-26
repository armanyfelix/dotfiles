{ config, dotfilesDir, pkgs, ... }:

{
  home.packages = [ pkgs.neovim ];

  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/modules/home/editors/neovim/config";
}
