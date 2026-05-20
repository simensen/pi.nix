{
  description = "Example: use pi-mono's mkPi builder directly from a downstream flake";

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
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
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

          # Compose a configured pi from the builder. The result is a normal
          # derivation usable anywhere a package is expected (home.packages,
          # environment.systemPackages, `nix run`, etc.).
          mypi = pi-mono.lib.${system}.mkPi {
            coding-agent = pi-mono.packages.${system}.coding-agent;

            rules = ''
              # Project rules
              - Prefer terse responses.
              - Cite file:line for code references.
            '';

            skills = [
              # ./skills/my-skill
            ];

            extensions = [
              # ./extensions/my-extension.ts
            ];

            extraFlags = [
              "--provider"
              "anthropic"
            ];

            environment = {
              # Each value is a path to a file whose contents become the env value.
              # ANTHROPIC_API_KEY = ./secrets/anthropic.key;
            };
          };
        in
        {
          default = mypi;
        }
      );
    };
}
