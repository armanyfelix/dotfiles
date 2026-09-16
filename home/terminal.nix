{ pkgs, inputs, config, dotfilesDir, ... }:

{
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/nvim";

  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/zsh/.zshrc";

  # Scripts auxiliares de Herdr. Viven en ~/.local/bin, la misma ruta que usa
  # la máquina de Fedora, para que config.toml sirva igual en las dos.
  home.file = {
    ".local/bin/herdr-split-pane".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/herdr/bin/herdr-split-pane";
    ".local/bin/herdr-focus-or-tab".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/herdr/bin/herdr-focus-or-tab";
    ".local/bin/herdr-agent-attention".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/herdr/bin/herdr-agent-attention";
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  xdg.configFile = {
    "btop/btop.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/btop/btop.conf";
    "fastfetch/config.jsonc".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/fastfetch/config.jsonc";
    "herdr/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/herdr/config.toml";
    "starship.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/starship.toml";
    "wezterm".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/wezterm";
  };

  home.packages = with pkgs; [
    wezterm
    btop
    cmatrix
    fastfetch
    pay-respects
    starship
    wget
    wl-clipboard
    zoxide
    jq
    # bat
    curl
    # fd
    # fzf
    ripgrep
    eza
    # unzip
    neovim
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
