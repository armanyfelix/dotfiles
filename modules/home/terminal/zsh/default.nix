{ config, dotfilesDir, pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh
    zsh-powerlevel10k
  ];

  home.file = {
    ".zshrc".source = config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/modules/home/terminal/zsh/config/.zshrc";
    ".p10k.zsh".source = config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/modules/home/terminal/zsh/config/.p10k.zsh";
  };
}
