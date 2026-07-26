{ config, dotfilesDir, pkgs, ... }:

{
  home.packages = [ pkgs.wezterm ];

  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/modules/home/terminal/wezterm/config";
}
