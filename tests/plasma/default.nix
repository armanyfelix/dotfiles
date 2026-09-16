{ pkgs ? (builtins.getFlake (toString ../..)).inputs.nixpkgs.legacyPackages.x86_64-linux }:

pkgs.stdenv.mkDerivation {
  pname = "plasma-lifetime-probe";
  version = "1";
  src = ./probe.c;
  dontUnpack = true;
  dontConfigure = true;
  nativeBuildInputs = [ pkgs.pkg-config pkgs.wayland-scanner ];
  buildInputs = [ pkgs.wayland ];
  buildPhase = ''
    protocol=${pkgs.wayland-protocols}/share/wayland-protocols/staging/ext-background-effect/ext-background-effect-v1.xml
    wayland-scanner client-header "$protocol" background-effect-client.h
    wayland-scanner private-code "$protocol" background-effect-protocol.c
    $CC -Wall -Wextra -Werror -I. "$src" background-effect-protocol.c \
      $(pkg-config --cflags --libs wayland-client) -o plasma-lifetime-probe
  '';
  installPhase = ''
    install -Dm755 plasma-lifetime-probe "$out/bin/plasma-lifetime-probe"
  '';
}
