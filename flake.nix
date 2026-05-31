{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
  in {
    nixosModules = import ./modules/nixos;
    homeModules = import ./modules/home-manager;
    overlays.default = final: _prev: {
      # Namespace for overlay users is 'mer'
      mer = import ./packages {pkgs = final;};
    };
    packages = forEachSystem (system:
      import ./packages {pkgs = nixpkgs.legacyPackages.${system};}
    );
  };
}
