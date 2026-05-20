{
  description = "pi-mono — prebuilt pi coding agent packaging";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";
  };

  outputs =
    { self, nixpkgs, jail-nix }:
    let
      versionData = builtins.fromJSON (builtins.readFile ./VERSION.json);
      version = nixpkgs.lib.removePrefix "v" versionData.rev;

      supportedSystems = builtins.attrNames versionData.systems;

      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;

      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = pkgsFor system;
          asset = versionData.systems.${system} or (throw "pi-mono: unsupported system ${system}");
          coding-agent = pkgs.callPackage ./coding-agent/package.nix {
            inherit system version asset;
          };
        in
        {
          inherit coding-agent;
          default = coding-agent;
        }
      );

      lib = forEachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        import ./lib {
          inherit pkgs;
          jail-nix = if pkgs.stdenv.hostPlatform.isLinux then jail-nix else null;
        }
      );

      formatter = forEachSystem (system: (pkgsFor system).nixfmt-rfc-style);

      overlays = {
        default = _final: prev: {
          pi-coding-agent = self.packages.${prev.stdenv.hostPlatform.system}.coding-agent;
        };
      };

      nixosModules = rec {
        default = coding-agent;
        coding-agent = import ./modules/nixos.nix self;
      };

      homeManagerModules = rec {
        default = coding-agent;
        coding-agent = import ./modules/home-manager.nix self;
      };
    };
}
