{ config, dotfilesDir, pkgs, ... }:

{
  home.packages = [
    (pkgs.yazi.override {
      _7zz = pkgs._7zz-rar;
    })
  ];

  home.file.".config/yazi".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/modules/home/terminal/yazi/config";
}
