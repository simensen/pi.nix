{
  cfg,
  pkgs,
  lib,
  mkPi,
}:

let
  environmentIsAttrs = cfg.environment != null && lib.isAttrs cfg.environment;
  environmentIsFile = cfg.environment != null && !lib.isAttrs cfg.environment;
  environmentFiles = lib.optionalAttrs environmentIsAttrs cfg.environment;

  builtPi = mkPi {
    coding-agent = cfg.package;
    inherit (cfg)
      rules
      skills
      extensions
      themes
      promptTemplates
      extraFlags
      ;
    environment = if environmentIsAttrs then cfg.environment else null;
  };

  wrappedPackage =
    if environmentIsFile then
      pkgs.writeShellScriptBin "pi" ''
        set -a
        . ${lib.escapeShellArg (toString cfg.environment)}
        set +a
        exec ${lib.escapeShellArg (lib.getExe builtPi)} "$@"
      ''
    else
      builtPi;

  invalidEnvNames = builtins.filter (
    name: builtins.match "[A-Za-z_][A-Za-z0-9_]*" name == null
  ) (builtins.attrNames environmentFiles);

  envNameAssertion = {
    assertion = invalidEnvNames == [ ];
    message = "programs.pi.coding-agent.environment contains invalid environment variable names: ${lib.concatStringsSep ", " invalidEnvNames}";
  };
in
{
  inherit wrappedPackage envNameAssertion environmentFiles;
}
