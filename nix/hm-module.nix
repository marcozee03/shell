self: {
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  cli-default = self.inputs.uva-cli.packages.${system}.default;
  shell-default = self.packages.${system}.with-cli;

  cfg = config.programs.uva;
in {
  imports = [
    (lib.mkRenamedOptionModule ["programs" "uva" "environment"] ["programs" "uva" "systemd" "environment"])
  ];
  options = with lib; {
    programs.uva = {
      enable = mkEnableOption "Enable Uva shell";
      package = mkOption {
        type = types.package;
        default = shell-default;
        description = "The package of Uva shell";
      };
      systemd = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable the systemd service for Uva shell";
        };
        target = mkOption {
          type = types.str;
          description = ''
            The systemd target that will automatically start the Uva shell.
          '';
          default = config.wayland.systemd.target;
        };
        environment = mkOption {
          type = types.listOf types.str;
          description = "Extra Environment variables to pass to the Uva shell systemd service.";
          default = [];
          example = [
            "QT_QPA_PLATFORMTHEME=gtk3"
          ];
        };
      };
      settings = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        description = "Uva shell settings";
      };
      extraConfig = mkOption {
        type = types.str;
        default = "";
        description = "Uva shell extra configs written to shell.json";
      };
      cli = {
        enable = mkEnableOption "Enable Uva CLI";
        package = mkOption {
          type = types.package;
          default = cli-default;
          description = "The package of Uva CLI"; # Doesn't override the shell's CLI, only change from home.packages
        };
        settings = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = "Uva CLI settings";
        };
        extraConfig = mkOption {
          type = types.str;
          default = "{}";
          description = "Uva CLI extra configs written to cli.json";
        };
      };
    };
  };

  config = let
    cli = cfg.cli.package;
    shell = cfg.package;
  in
    lib.mkIf cfg.enable {
      systemd.user.services.uva = lib.mkIf cfg.systemd.enable {
        Unit = {
          Description = "Uva Shell Service";
          After = [cfg.systemd.target];
          PartOf = [cfg.systemd.target];
          X-Restart-Triggers = lib.mkIf (cfg.settings != {}) [
            "${config.xdg.configFile."uva/shell.json".source}"
          ];
        };

        Service = {
          Type = "exec";
          ExecStart = "${shell}/bin/uva-shell";
          Restart = "on-failure";
          RestartSec = "5s";
          TimeoutStopSec = "5s";
          Environment =
            [
              "QT_QPA_PLATFORM=wayland"
            ]
            ++ cfg.systemd.environment;

          Slice = "session.slice";
        };

        Install = {
          WantedBy = [cfg.systemd.target];
        };
      };

      xdg.configFile = let
        mkConfig = c:
          lib.pipe (
            if c.extraConfig != ""
            then c.extraConfig
            else "{}"
          ) [
            builtins.fromJSON
            (lib.recursiveUpdate c.settings)
            builtins.toJSON
          ];
      in {
        "uva/shell.json".text = mkConfig cfg;
        "uva/cli.json".text = mkConfig cfg.cli;
      };

      home.packages = [shell] ++ lib.optional cfg.cli.enable cli;
    };
}
