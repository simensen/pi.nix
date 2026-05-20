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

  options.programs.pi.coding-agent.users = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    defaultText = lib.literalExpression "[ ] (interpreted as all normal users)";
    description = ''
      Normal users whose `~/.pi/agent` should be managed.

      An empty list means all normal users.
    '';
    example = [ "lukas" ];
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion =
              let
                invalid = builtins.filter (
                  name:
                  !(builtins.hasAttr name (lib.filterAttrs (_: user: user.isNormalUser or false) config.users.users))
                ) cfg.users;
              in
              invalid == [ ];
            message =
              let
                invalid = builtins.filter (
                  name:
                  !(builtins.hasAttr name (lib.filterAttrs (_: user: user.isNormalUser or false) config.users.users))
                ) cfg.users;
              in
              "programs.pi.coding-agent.users contains unknown or non-normal users: ${lib.concatStringsSep ", " invalid}";
          }
          helpers.envNameAssertion
        ];

        environment.systemPackages = [ helpers.wrappedPackage ];
      }

      (lib.mkIf (cfg.models != null) (
        let
          rules = [
            "d %h/.pi 0700 - - -"
            "d %h/.pi/agent 0700 - - -"
            "L+ %h/.pi/agent/models.json - - - - ${cfg.models}"
          ];
        in
        lib.mkMerge [
          (lib.mkIf (cfg.users == [ ]) {
            systemd.user.tmpfiles.rules = rules;
          })
          (lib.mkIf (cfg.users != [ ]) {
            systemd.user.tmpfiles.users = builtins.listToAttrs (
              map (name: {
                inherit name;
                value.rules = rules;
              }) cfg.users
            );
          })
        ]
      ))
    ]
  );
}
