# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Tijuana";

  # Select internationalisation properties.
  i18n.defaultLocale = "es_MX.UTF-8";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.lafv = {
    isNormalUser = true;
    description = "lafv";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
      kdePackages.krunner
    #  thunderbird
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "lafv";

  # Install firefox.
  programs.firefox.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
    # 🚀 ALIASES ESPECÍFICOS PARA TU STACK
    shellAliases = {
      # NixOS
      nix-search = "nix search nixpkgs";
      nix-update = "sudo nix-channel --update";
      nix-rebuild = "sudo nixos-rebuild switch";
      nix-opt = "sudo nix-collect-garbage --delete-older-than 7d";
      nix-shell-node = "nix-shell -p nodejs pnpm bun";

      # Editores
      vim = "nvim";
      z = "zed";

      # Node.js ecosystem
      nr = "npm run";
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
      neo = "neofetch";
      matrix = "cmatrix";
      f = "pay-respects";

      # Kitty
      icat = "kitty +kitten icat";
      diff = "kitty +kitten diff";
    };
  };

  users.defaultUserShell = pkgs.zsh;


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    nodejs_24
    pnpm
    bun
    cargo
    kitty
    floorp
    neofetch
    zed-editor
    obs-studio
    btop
    cmatrix
    pay-respects
    wezterm
    (pkgs.writeShellScriptBin "zed" ''
      exec ${pkgs.zed-editor}/libexec/zed-editor "$@"
    '')
  ];

  fonts = {
    packages = with pkgs; [
      nerd-fonts.terminess-ttf
      nerd-fonts.blex-mono
      ibm-plex
      openmoji-color
    ];
    fontconfig = {
        defaultFonts = {
          sansSerif = [ "IBM Plex Sans" ];
          serif = [ "IBM Plex Serif" ];
          monospace = [ "Terminess Nerd Font" ];
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

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}

