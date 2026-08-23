{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Tijuana";
  i18n.defaultLocale = "es_MX.UTF-8";
  security.rtkit.enable = true;
  console.keyMap = "us";

  services = {
    openssh.enable = true;
    printing.enable = true;
    tuned.enable = true;
    upower.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = false;
      alsa.support32Bit = false;
      pulse.enable = true;
    };
    flatpak.enable = true;
    desktopManager.plasma6.enable = true;
    xserver.videoDrivers = [ "nvidia" ];
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      autoLogin = {
        enable = false;
        user = "armanix";
      };
    };
  };

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.deafult = "gtk";

  users.users."armanix" = {
    isNormalUser = true;
    description = "armanix";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
      kdePackages.qtstyleplugin-kvantum
      unityhub
      thunderbird
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-36.9.5"
  ];

  programs = {
    gamemode.enable = true;
    gamescope.enable = true;
    nix-ld.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    kdeconnect.enable = true;
  };

  environment.systemPackages = with pkgs; [
    (heroic.override {
      extraPkgs = gamePkgs: [ gamePkgs.gamescope ];
    })
    wineWow64Packages.stable
    wineWow64Packages.waylandFull
  ];

  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      sync.enable = true;
      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:5:0:0";
    };
  };
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy.AutoEnable = true;
    };
  };

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

  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      # NixOS
      np = "nix search nixpkgs --extra-experimental-features";
      nu = "sudo nix-channel --update";
      nrs = "sudo nixos-rebuild switch";
      nix-opt = "sudo nix-collect-garbage --delete-older-than 7d";
      nix-shell-node = "nix-shell -p nodejs pnpm bun";
      ns = "nix-shell -p";
      # Editores
      v = "nvim";
      # Node.js ecosystem
      nd = "npm run dev";
      nb = "npm run build";
      nt = "npm test";
      pn = "pnpm";
      pnr = "pnpm run";
      pnd = "npm run dev";
      pnb = "npm run build";
      # Rust
      cb = "cargo build";
      cr = "cargo run";
      ct = "cargo test";
      cf = "cargo fmt";
      cc = "cargo check";
      # Git shortcuts mejorados
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      gd = "git diff";
      gco = "git checkout";
      gcb = "git checkout -b";
      # Sistema
      top = "btop";
      ff = "fastfetch";
      matrix = "cmatrix";
      f = "pay-respects";
      nvidia-watch ="watch -n 2 nvidia-smi";
    };
  };

  users.defaultUserShell = pkgs.zsh;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "26.05";

}
