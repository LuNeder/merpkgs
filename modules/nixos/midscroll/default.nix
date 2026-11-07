# Stolen from the PR: https://github.com/VPavliashvili/midscroll-flake/blob/main/flake.nix

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.merpkgs.services.midscroll;

  defaultPkg = 
    if pkgs ? merpkgs && pkgs.merpkgs ? midscroll then pkgs.merpkgs.midscroll
    else null;

  formatValue =
    v:
    if builtins.isBool v then
      (if v then "true" else "false")
    else if builtins.isList v then
      lib.concatStringsSep ", " (map toString v)
    else
      toString v;

  confText =
    lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} = ${formatValue v}") cfg.settings)
    + "\n";
in
{
  options.merpkgs.services.midscroll = {
    enable = lib.mkEnableOption "midscroll, FOSS Middle Mouse Scroll replacement for Linux";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = defaultPkg;
      description = "The midscroll package to use.";
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          str
          int
          float
          bool
          (listOf str)
        ]);
      default = { };
      example = {
        SPEED_MULT = 0.01;
        NATURAL = true;
        # those apps have native middle scroll on linux
        # blacklisting them makes sense.
        # those programs are blacklisted by default as author suggests it
        BLACKLIST = [
          "freecad"
          "orcaslicer"
          "minecraft"
        ];
      };
      description = ''
        Settings rendered into /etc/midscroll.conf, in midscroll's
        own `KEY = value` format (see the upstream README's Tuning
        section for the full list of options).
      '';
    };

    overlay.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enabling per-user service, midscroll-overlay.
        It makes possible to to see scroll badge and ghost cursor.
        Main functionality and systemd daemon works without this,
        but visual feedback will be lacking.
        Also, its important to know that as for now this only works with KDE using kdotool.
        other wayland compositors are not compatible. Can't say much about xorg
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.package != null;
      message = "midscroll package not found. Please add the merpkgs overlay or set services.midscroll.package manually.";
    }];

    boot.kernelModules = [ "uinput" ];

    environment.systemPackages = [ cfg.package ];

    environment.etc."midscroll.conf" = lib.mkIf (cfg.settings != { }) {
      text = confText;
    };

    systemd.tmpfiles.rules = lib.mkIf (cfg.settings == { }) [
      "C /etc/midscroll.conf 0644 root root - ${cfg.package}/share/midscroll/midscroll.conf"
    ];

    security.polkit.enable = true;

    systemd.services.midscroll = {
      description = "midscroll - FOSS autoscroll for Linux";
      wants = [ "modprobe@uinput.service" ];
      after = [ "modprobe@uinput.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/midscroll";
        Restart = "always";
        RestartSec = 2;
        RuntimeDirectory = "midscroll";
        CPUSchedulingPolicy = "fifo";
        CPUSchedulingPriority = 20;

        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateNetwork = true;
        IPAddressDeny = "any";
        RestrictAddressFamilies = "AF_UNIX";
        ProtectProc = "invisible";
        ProcSubset = "pid";
        ProtectKernelTunables = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
        MemoryMax = "128M";
        TasksMax = 32;
        SystemCallFilter = "@system-service";
        SystemCallErrorNumber = "EPERM";
        MemoryDenyWriteExecute = true;
      };
    };

    systemd.user.services.midscroll-overlay = lib.mkIf cfg.overlay.enable {
      description = "visual feedback for midscroll";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/midscroll-overlay";
        Restart = "on-failure";
        RestartSec = 2;

        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        ProtectSystem = "full";
        ProtectKernelTunables = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
        RestrictAddressFamilies = "AF_UNIX AF_NETLINK";
        UMask = "0077";
        TasksMax = 64;
        SystemCallFilter = "@system-service";
        SystemCallErrorNumber = "EPERM";
      };
    };
  };
}