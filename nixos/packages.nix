{ pkgs, ... }:
with pkgs;   [
  unityhub
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
  xwayland-satellite
  fuzzel
  brave
  obsidian
#     opencode
  thunderbird
  wineWowPackages.stable
  wineWowPackages.waylandFull
#     appflowy
#     emacs
  kdePackages.kate
  kdePackages.krunner
  (heroic.override {
   extraPkgs = pkgs: [
   pkgs.gamescope
   ];
   })
(yazi.override {
 _7zz = _7zz-rar;
 })
 libreoffice-qt
 hunspell
 hunspellDicts.es_MX
 hunspellDicts.en_US
]
