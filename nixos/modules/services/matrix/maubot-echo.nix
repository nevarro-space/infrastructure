{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.maubot-echo;
  maubot = pkgs.callPackage ../../../pkgs/maubot.nix { };

  maubotEchoStandaloneCfg = {
    user = {
      credentials = {
        id = cfg.username;
        homeserver = cfg.homeserver;
      };
      sync = true;
      autojoin = true;
      displayname = "Ping [nevarro.space]";
      avatar_url = "mxc://nevarro.space/HsqBELNFqoZpzFgIqbxJRMIX";
      ignore_initial_sync = true;
      ignore_first_sync = true;
    };
    database = "sqlite://${cfg.dataDir}/ping.db";
    logging = {
      version = 1;
      formatters.journal_fmt.format = "%(name)s: %(message)s";
      handlers.journal = {
        class = "systemd.journal.JournalHandler";
        formatter = "journal_fmt";
      };
      loggers = {
        maubot.level = "DEBUG";
        mau.level = "DEBUG";
        aiohttp.level = "INFO";
      };
      root = {
        level = "DEBUG";
        handlers = [ "journal" ];
      };
    };
  };
  format = pkgs.formats.yaml { };
  configYaml = format.generate "config.yaml" maubotEchoStandaloneCfg;
in
{
  options = {
    services.maubot-echo = {
      enable = mkEnableOption "Echo maubot";
      username = mkOption { type = types.str; };
      homeserver = mkOption { type = types.str; };
      secretYAML = mkOption { type = types.path; };
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/maubot-echo";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.maubot-echo = {
      description = "Echo Maubot";
      after =
        [ "matrix-synapse.target" "echo_maubot_secrets_yaml-key.service" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ${pkgs.git}/bin/git clone https://github.com/maubot/echo src
        cp -r src/* .
        rm -rf src
        ${pkgs.yq-go}/bin/yq ea '. as $item ireduce ({}; . * $item )' \
          ${configYaml} ${cfg.secretYAML} > config.yaml
      '';
      serviceConfig = {
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${maubot}/bin/standalone";
        Restart = "on-failure";
        User = "maubot-echo";
        Group = "maubot-echo";
        SupplementaryGroups = [ "keys" ];
      };
    };

    users = {
      users.maubot-echo = {
        group = "maubot-echo";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.maubot-echo = { };
    };
  };
}
