{ pkgs, inputs, config, dotfilesDir, ... }:

{
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/nvim";

  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/zsh/.zshrc";

  xdg.configFile = {
    "btop/btop.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/btop/btop.conf";
    "fastfetch/config.jsonc".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/fastfetch/config.jsonc";
    "herdr/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/herdr/config.toml";
    "starship.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/starship.toml";
    "wezterm/commands/init.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/wezterm/commands/init.lua";
    "wezterm/commands/toggle-transparency.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/wezterm/commands/toggle-transparency.lua";
    "wezterm/wezterm.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/terminal/wezterm/wezterm.lua";
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
    # bat
    curl
    # fd
    # fzf
    git
    # jq
    # ripgrep
    eza
    # unzip
    neovim
    claude-code
    codex
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    nodejs_26
    pnpm
    bun
    cargo
  ];
}
