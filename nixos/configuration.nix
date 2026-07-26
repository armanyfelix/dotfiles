{ config, pkgs, ... }:

{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
    ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      # PRIME Sync and Offload cannot be both enabled
      # offload = {
      # enable = true;
      # enableOffloadCmd = true;
      # };
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
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };

  networking.hostName = "armanix"; # Define your hostname.
  networking.networkmanager.enable = true;
  services.tuned.enable = true;
  services.upower.enable = true;
  time.timeZone = "America/Tijuana";
  i18n.defaultLocale = "es_MX.UTF-8";
  services.xserver.enable = false;
# Enable the KDE Plasma Desktop Environment.
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
};
  programs.niri.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glib
    nspr
    nss
  ];

  console.keyMap = "us";
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = false;
    alsa.support32Bit = false;
    pulse.enable = true;
  };
  services.flatpak.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "gtk";
  users.users.lafv = {
    isNormalUser = true;
    description = "lafv";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
  };
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "lafv";
  nixpkgs.config.allowUnfree = true;
  programs.kdeconnect.enable = true;
  programs.firefox.enable = false;
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-36.9.5"
  ];
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  environment.systemPackages = with pkgs; [
  unityhub
  neovim
  wget
  git
  fastfetch
  #obs-studio
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
# thunderbird
  wineWow64Packages.stable
  wineWow64Packages.waylandFull
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
 #libreoffice-qt
 #hunspell
 #hunspellDicts.es_MX
 #hunspellDicts.en_US
];
#     import ./packages.nix { inherit pkgs; };


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
    fontconfig = {
        defaultFonts = {
          sansSerif = [ "Inter" ];
          serif = [ "Inter Serif" ];
          monospace = [ "JetBrainsMono Nerd Font" ];
          emoji = [ "OpenMoji Color" ];
        };
    };
    enableDefaultPackages = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

programs.zsh = {
  enable = true;
  enableBashCompletion = true;
  autosuggestions.enable = true;
  syntaxHighlighting.enable = true;
  ohMyZsh = {
    enable = true;
    plugins = [
      # 🎯 ESENCIALES PARA TODOS
      "git"               # Aliases git: gst, gaa, gcm, gl, gp, etc.
      "sudo"              # Doble ESC para añadir sudo
      "extract"           # `x archivo.zip` - extrae CUALQUIER cosa
      "z"                 # Navegación inteligente: `z proyecto`
      "history"           # `h`, `hsi busqueda` - historial fácil
      "colored-man-pages" # Manuales a color (cero overhead)
      # 🔧 PARA NIXOS
      "command-not-found" # Te dice cómo instalar con nix
      # ⚡ TU STACK DE DESARROLLO
      "npm"               # Autocompletado npm/yarn/pnpm
      "node"              # Shortcuts: `node-docs`, `npm-search`
      "rust"              # Autocompletado cargo, `rc`, `rb`
      "dotenv"            # load your project ENV variables from .env file when you cd into project root directory
      # 🐳 DEVOPS/HERRAMIENTAS
      "docker"            # Autocompletado docker/docker-compose
      "docker-compose"    # Aliases: `dcup`, `dcdown`
      # 💻 PRODUCTIVIDAD EDITORES
      "vi-mode"           # Atajos vim en zsh (ideal para neovim/zed)
      "copyfile"          # `copyfile archivo` copia contenido
      "copypath"          # `copypath` copia ruta actual
      "dirhistory"        # Navegación directorios con alt+←/→
      # 🎨 EXTRAS ÚTILES
      "web-search"        # `google algo`, `ddg algo`, `github algo`
      "urltools"          # Encode/decode URLs: `urlencode`, `urldecode`
      "jsontools"         # Formatear JSON: `pp_json`, `is_json`
    ];
    custom = "$HOME/.oh-my-zsh/custom/";
    theme = "powerlevel10k/powerlevel10k";
  };

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

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  system.stateVersion = "25.11";

}

