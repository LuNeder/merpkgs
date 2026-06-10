{lib, pkgs, config}: {
  # Interface
  options = {
    merpkgs.services.foo = {
      # ...
    };
  };

  # Implementation
  config = lib.mkIf config.merpkgs.services.foo.enable {
    # ...
  };
}
