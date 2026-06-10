{
  description = "🧜‍♀️ Luana's nix package repository. Includes packages such as catask and buttui, as well as beta or alternative versions of packages I maintain on nixpkgs.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {self, nixpkgs, ...}: let
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in {
    nixosModules = import ./modules/nixos;
    homeModules = import ./modules/home-manager;
    overlays.default = final: _prev: {
      # Namespace for overlay users is 'merpkgs'
      merpkgs = import ./packages {pkgs = final;};
    };
    packages = forAllSystems (system:
      import ./packages {pkgs = nixpkgs.legacyPackages.${system};}
    );
  };
}
