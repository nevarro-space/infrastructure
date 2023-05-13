{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.msclinkbot;
  msclinkbot = pkgs.callPackage ../../../pkgs/msclinkbot.nix { };

  mscLinkBotConfig = {
    username = cfg.username;
    homeserver = cfg.homeserver;
    password_file = cfg.passwordFile;

    auto_join = true;

    database = {
      type = "sqlite3";
      uri = "${cfg.dataDir}/msclinkbot.db";
    };

    logging = {
      min_level = "debug";
      writers = [
        { type = "stdout"; format = "json"; }
      ];
    };
  };
  format = pkgs.formats.yaml { };
  mscLinkBotConfigFile = format.generate "msclinkbot.config.yaml" mscLinkBotConfig;
in
{
  options = {
    services.msclinkbot = {
      enable = mkEnableOption "MSC Link Bot";
      username = mkOption { type = types.str; };
      homeserver = mkOption { type = types.str; };
      passwordFile = mkOption { type = types.path; };
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/msclinkbot";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.msclinkbot = {
      description = "MSC Link Bot";
      after = [
        "matrix-synapse.target"
        "mscbot_password-key.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${msclinkbot}/bin/msc-link-bot --config ${mscLinkBotConfigFile}
        '';
        Restart = "on-failure";
        User = "msclinkbot";
        Group = "msclinkbot";
        SupplementaryGroups = [ "keys" ];
      };
    };

    users = {
      users.msclinkbot = {
        group = "msclinkbot";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.msclinkbot = { };
    };

    # Add a backup service.
    services.backup.backups.msclinkbot = {
      path = cfg.dataDir;
    };
  };
}
