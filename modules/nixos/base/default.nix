{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;

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
  };

  security.rtkit.enable = true;
  time.timeZone = "America/Tijuana";
  i18n.defaultLocale = "es_MX.UTF-8";
  console.keyMap = "us";

  users.users.lafv = {
    isNormalUser = true;
    description = "lafv";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
  };
  users.defaultUserShell = pkgs.zsh;

  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      np = "nix search nixpkgs --extra-experimental-features";
      nu = "sudo nix-channel --update";
      nrs = "sudo nixos-rebuild switch --flake path:/home/lafv/Dotfiles#armanix";
      nix-opt = "sudo nix-collect-garbage --delete-older-than 7d";
      nix-shell-node = "nix-shell -p nodejs pnpm bun";
      ns = "nix-shell -p";
      v = "nvim";
      nd = "npm run dev";
      nb = "npm run build";
      nt = "npm test";
      pn = "pnpm";
      pnr = "pnpm run";
      pnd = "npm run dev";
      pnb = "npm run build";
      cb = "cargo build";
      cr = "cargo run";
      ct = "cargo test";
      cf = "cargo fmt";
      cc = "cargo check";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      gd = "git diff";
      gco = "git checkout";
      gcb = "git checkout -b";
      top = "btop";
      ff = "fastfetch";
      matrix = "cmatrix";
      f = "pay-respects";
      nvidia-watch = "watch -n 2 nvidia-smi";
    };
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ glib nspr nss ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.11";
}
