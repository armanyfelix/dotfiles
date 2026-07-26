{ config, dotfilesDir, ... }:

{
  home.file.".config/niri".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/modules/home/desktop/niri/config";
}
