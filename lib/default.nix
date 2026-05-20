{
  pkgs,
  lib ? pkgs.lib,
  jail-nix ? null,
}:

{
  mkPi = import ./mk-pi.nix { inherit pkgs lib; };
}
// lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux && jail-nix != null) {
  mkJailedPi = import ./mk-jailed-pi.nix {
    inherit pkgs lib;
    jail = jail-nix.lib.init pkgs;
  };
}
