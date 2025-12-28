{ config, pkgs, ... }:

{
  home.username = "lafv";
  home.homeDirectory = "/home/lafv";
  home.stateVersion = "25.11";

  home.file.".zshrc".source = /home/lafv/Dotfiles/.zshrc;
  home.file.".p10k.zsh".source = /home/lafv/Dotfiles/.p10k.zsh;
  home.file.".config/nvim".source = /home/lafv/Dotfiles/.config/nvim;
  home.file.".config/yazi".source = /home/lafv/Dotfiles/.config/yazi;
  home.file.".config/niri".source = /home/lafv/Dotfiles/.config/niri;
  home.file.".config/wezterm".source = /home/lafv/Dotfiles/.config/wezterm;
  home.file.".config/zed".source = /home/lafv/Dotfiles/.config/zed;

  home.packages = with pkgs; [
    tree
    bat
  ];
}
