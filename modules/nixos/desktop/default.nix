{ pkgs, ... }:

{
  services.xserver.enable = false;
  services.desktopManager.plasma6.enable = true;
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    autoLogin = {
      enable = true;
      user = "lafv";
    };
  };

  programs = {
    appimage = {
      enable = true;
      binfmt = true;
    };
    firefox.enable = false;
    kdeconnect.enable = true;
    niri.enable = true;
  };

  services.flatpak.enable = true;
  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  environment.systemPackages = with pkgs; [
    fuzzel
    kdePackages.kate
    kdePackages.krunner
    unityhub
    xwayland-satellite
  ];

  fonts = {
    packages = with pkgs; [
      nerd-fonts._0xproto
      nerd-fonts.terminess-ttf
      nerd-fonts.go-mono
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term
      nerd-fonts.iosevka-term-slab
      nerd-fonts.jetbrains-mono
      nerd-fonts.monofur
      nerd-fonts.tinos
      nerd-fonts.departure-mono
      monaspace
      inter
      openmoji-color
      open-sans
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Inter" ];
      serif = [ "Inter Serif" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
      emoji = [ "OpenMoji Color" ];
    };
    enableDefaultPackages = true;
  };
}
