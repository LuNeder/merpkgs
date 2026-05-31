# NUR compatible entry point
 
# pkgs is provided by NUR user
{pkgs}: {
  nixosModules = import ./modules/nixos;
  homeModules = import ./modules/home-manager;
  overlays.default = final: _prev: {
    mer = import ./packages {pkgs = final;};
  };
}
# Import rest of packages directly to top level
// import ./packages {inherit pkgs;}
