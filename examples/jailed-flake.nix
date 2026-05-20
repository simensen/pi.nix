{
  description = "Example: build a jailed pi with mkJailedPi (Linux only)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    pi-mono.url = "github:simensen/pi.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      pi-mono,
    }:
    let
      # mkJailedPi is Linux-only — bubblewrap requires Linux user namespaces.
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = pkgsFor system;

          # First build a configured pi via mkPi.
          mypi = pi-mono.lib.${system}.mkPi {
            coding-agent = pi-mono.packages.${system}.coding-agent;
            rules = ''
              # Project rules
              - Prefer terse responses.
            '';
          };

          # Then wrap it in a bubblewrap jail. The result is a normal
          # derivation that sets up the namespace sandbox before exec'ing pi.
          jailed = pi-mono.lib.${system}.mkJailedPi {
            inner = mypi;

            # Binaries that should be on PATH inside the jail.
            allowedPkgs = with pkgs; [
              git
              ripgrep
              fd
              nodejs
            ];

            # Writable paths relative to ~/.pi/ inside the jail.
            # `agent` covers models.json, sessions, prompts, etc.
            stateDirs = [ "agent" ];

            # Env vars to forward from the host (try-fwd-env — silent if unset).
            forwardEnv = [
              "ANTHROPIC_API_KEY"
              "OPENAI_API_KEY"
            ];

            # Network access is on by default; flip to false for offline-only.
            network = true;
          };
        in
        {
          default = jailed;
        }
      );
    };
}
