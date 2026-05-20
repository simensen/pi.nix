self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.pi.coding-agent;

  mkPi = self.lib.${pkgs.stdenv.hostPlatform.system}.mkPi;

  helpers = import ./_lib.nix {
    inherit cfg pkgs lib mkPi;
  };
in
{
  imports = [ (import ./common.nix { inherit self; }) ];

  config = lib.mkIf cfg.enable {
    assertions = [ helpers.envNameAssertion ];

    home.packages = [ helpers.wrappedPackage ];

    home.file = lib.mkIf (cfg.models != null) {
      ".pi/agent/models.json".source = cfg.models;
    };
  };
}
