{ config, dotfilesDir, pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh
  ];

  home.file = {
    ".zshrc".source = config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/modules/home/terminal/zsh/config/.zshrc";
    ".config/starship.toml".source = config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/modules/home/terminal/zsh/config/starship.toml";
  };
}
