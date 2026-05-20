{ self }:
{
  lib,
  pkgs,
  ...
}:

{
  options.programs.pi.coding-agent = {
    enable = lib.mkEnableOption "pi agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent;
      defaultText = lib.literalExpression "inputs.pi-mono.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent";
      description = "The pi coding agent package to install.";
    };

    rules = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      description = ''
        Extra instructions to append to pi's system prompt via `--append-system-prompt`.
      '';
      example = ''
        # Rules
        - Be concise.
        - Make no mistakes.
      '';
    };

    skills = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Skill paths to pass to pi via repeated `--skill` flags for every invocation.
      '';
      example = lib.literalExpression ''
        [
          ./skills/my-skill
          ./skills/nixpkgs
        ]
      '';
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Extension paths to pass to pi via repeated `--extension` flags for every invocation.
      '';
      example = lib.literalExpression ''
        [
          ./extensions/my-extension.ts
        ]
      '';
    };

    themes = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Theme paths to pass to pi via repeated `--theme` flags for every invocation.
      '';
      example = lib.literalExpression ''
        [
          ./themes/catppuccin-mocha.json
        ]
      '';
    };

    promptTemplates = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Prompt template paths to pass to pi via repeated `--prompt-template` flags for every invocation.
      '';
      example = lib.literalExpression ''
        [
          ./prompts
          ./prompt-templates/review.md
        ]
      '';
    };

    models = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a custom `models.json` file to keep at `~/.pi/agent/models.json`.

        This file defines custom providers and models for pi to use.
        When set to `null`, nothing is managed and pi uses its default models.
      '';
      example = lib.literalExpression ''
        ./models.json
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Extra raw CLI arguments to always append when launching pi.
      '';
      example = lib.literalExpression ''
        [ "--provider" "openai" "--model" "gpt-5" ]
      '';
    };

    environment = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.path (lib.types.attrsOf lib.types.path));
      default = null;
      description = ''
        Extra environment to set before launching pi.

        This can either be a shell environment file that is sourced with `set -a`,
        or an attribute set mapping environment variable names to files whose contents
        should be exported as the variable values.
      '';
      example = lib.literalExpression ''
        {
          OPENAI_API_KEY = config.age.secrets.openai.path;
          ANTHROPIC_API_KEY = config.age.secrets.anthropic.path;
        }
      '';
    };
  };
}
