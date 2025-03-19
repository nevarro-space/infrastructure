{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.meetbot;

  meetbotConfig = {
    listen = ":7890";
    username = cfg.username;
    homeserver = cfg.homeserver;
    displayname = "Google Meet";
    avatar_url = "mxc://nevarro.space/EQldsaNpqiGPJCatXiLeUTIb";

    user_id_to_email = import ../../../../secrets/matrix/meetbot-emails.nix;

    database = {
      type = "sqlite3-fk-wal";
      uri = "${cfg.dataDir}/meetbot.db?_txlock=immediate";
    };

    logging = {
      min_level = "debug";
      writers = [{
        type = "stdout";
        format = "json";
      }];
    };
  };
  format = pkgs.formats.yaml { };
  meetbotConfigFile = format.generate "meetbot.config.yaml" meetbotConfig;
in {
  options = {
    services.meetbot = {
      enable = mkEnableOption "Meetbot";
      username = mkOption { type = types.str; };
      homeserver = mkOption { type = types.str; };
      secretEnv = mkOption { type = types.path; };
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/meetbot";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.meetbot = {
      description = "Meetbot";
      wantedBy = [ "multi-user.target" ];
      after = [
        config.services.matrix-synapse.serviceUnit
        "meetbot_secret_env-key.service"
      ];
      requires = [
        config.services.matrix-synapse.serviceUnit
        "meetbot_secret_env-key.service"
      ];
      wants = [
        config.services.matrix-synapse.serviceUnit
        "meetbot_secret_env-key.service"
      ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.meetbot}/bin/meetbot --config ${meetbotConfigFile}
        '';
        EnvironmentFile = cfg.secretEnv;
        Restart = "on-failure";
        User = "meetbot";
        Group = "meetbot";
        SupplementaryGroups = [ "keys" ];
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "meetbot.nevarro.space" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://0.0.0.0:7890"; # without a trailing /
            extraConfig = ''
              access_log /var/log/nginx/meetbot.access.log;
            '';
          };
        };
      };
    };

    users = {
      users.meetbot = {
        group = "meetbot";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.meetbot = { };
    };

    # Add a backup service.
    services.backup.backups.meetbot = { path = cfg.dataDir; };
  };
}
