{ pkgs, ... }:
with pkgs;   [
    neovim
    wget
    git
    nodejs_24
    pnpm
    bun
    fastfetch
    obs-studio
    btop
    cmatrix
    pay-respects
    wezterm
    zoxide
    vlc
    signal-desktop
    blender
    xwayland-satellite
    fuzzel
    kicad
    brave
    obsidian
#     opencode
    thunderbird
    wineWowPackages.stable
    wineWowPackages.waylandFull
    dbeaver-bin
#     emacs
    kdePackages.kate
    kdePackages.krunner
    discord
    (heroic.override {
     extraPkgs = pkgs: [
     pkgs.gamescope
     ];
     })
    (yazi.override {
     _7zz = _7zz-rar;
    })
]
