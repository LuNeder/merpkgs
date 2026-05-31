{lib, pkgs, config}: {
  # Interface
  options = {
    mer.services.foo = {
      # ...
    };
  };

  # Implementation
  config = lib.mkIf config.mer.services.foo.enable {
    # ...
  };
}
