{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.merpkgs.services.ensureAlpinePackages;
in
{
  options = {
    merpkgs.services.ensureAlpinePackages = {
      enable = lib.mkEnableOption "ensureAlpinePackages";

      packages = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "List of Alpine/postmarketOS packages to install with apk";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.packages != null;
      message = "ensureAlpinePackages enabled but no packages provided";
    }];

    systemd.services.ensureAlpinePackages = {
      description = "apk runner";
      serviceConfig = {
        # Currently Catask does not let you override config or mutable paths, so this very cursed script is needed
        ExecStart = pkgs.writeScript "ensureAlpinePackages" ''
          #!${pkgs.runtimeShell}
          /usr/sbin/apk add --interactive=no ${lib.concatStringsSep " " cfg.packages}
        '';
        User = "root";
        Restart = "on-failure";
        RestartSec = 120;
      };
      wantedBy = [ "multi-user.target" ];
      wants = [ "network.target" ];
    };
  };

  meta.maintainers = [ lib.maintainers.luNeder ];
}