{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/nixos/personal.nix
    ../../modules/nixos/hardware/nvidia.nix
  ];

  networking.hostName = "armanix";
}
