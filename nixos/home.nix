{ config, inputs, pkgs, ... }:
{
  home.username = "lafv";
  home.homeDirectory = "/home/lafv";
  home.stateVersion = "25.11";
  programs.git.enable = true;

  home.file.".zshrc".source = /home/lafv/dotfiles/.zshrc;
  home.file.".p10k.zsh".source = /home/lafv/dotfiles/.p10k.zsh;
  home.file.".config/nvim".source = /home/lafv/dotfiles/.config/nvim;
  home.file.".config/yazi".source = /home/lafv/dotfiles/.config/yazi;
  home.file.".config/niri".source = /home/lafv/dotfiles/.config/niri;
  home.file.".config/wezterm".source = /home/lafv/dotfiles/.config/wezterm;
  home.file.".config/zed".source = /home/lafv/dotfiles/.config/zed;

  home.packages = with pkgs; [
    tree
    bat
    inputs.zed.packages.${pkgs.system}.default
#     inputs.zen-browser.packages.${pkgs.system}.default
  ];

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
