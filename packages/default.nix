{pkgs}: {
  example = pkgs.callPackage ./example {};
  buttui = pkgs.callPackage ./buttui {};
}
