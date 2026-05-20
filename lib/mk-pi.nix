{
  pkgs,
  lib ? pkgs.lib,
}:

{
  coding-agent,
  name ? "pi",
  rules ? null,
  skills ? [ ],
  extensions ? [ ],
  themes ? [ ],
  promptTemplates ? [ ],
  extraFlags ? [ ],
  environment ? null,
}:

let
  rulesPath = if rules == null then null else pkgs.writeText "pi-AGENTS.md" rules;

  pathFlags =
    flag: paths:
    lib.concatMap (path: [
      flag
      (toString path)
    ]) paths;

  resourceArgs =
    lib.optionals (rulesPath != null) [
      "--append-system-prompt"
      (toString rulesPath)
    ]
    ++ pathFlags "--skill" skills
    ++ pathFlags "--extension" extensions
    ++ pathFlags "--theme" themes
    ++ pathFlags "--prompt-template" promptTemplates;

  wrapperPrelude = lib.optionalString (environment != null) (
    lib.concatLines (
      lib.mapAttrsToList (envName: path: ''
        export ${envName}="$(cat ${lib.escapeShellArg (toString path)})"
      '') environment
    )
  );

  wrapperArgs = lib.concatMapStringsSep " " lib.escapeShellArg resourceArgs;
  extraFlagsArgs = lib.concatMapStringsSep " " lib.escapeShellArg extraFlags;

  needsWrapper = resourceArgs != [ ] || environment != null || extraFlags != [ ];
in
if !needsWrapper && name == "pi" then
  coding-agent
else
  pkgs.writeShellScriptBin name ''
    ${wrapperPrelude}
    case "''${1-}" in
      install|remove|uninstall|update|list|config)
        exec ${lib.escapeShellArg (lib.getExe coding-agent)} "$@"
        ;;
      *)
        exec ${lib.escapeShellArg (lib.getExe coding-agent)} ${wrapperArgs} ${extraFlagsArgs} "$@"
        ;;
    esac
  ''
