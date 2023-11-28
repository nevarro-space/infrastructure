{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.mautrix-slack;

  mautrix-slack = pkgs.callPackage ../../../pkgs/mautrix-slack.nix { };

  mautrixSlackAppserviceConfig = {
    id = "slack";
    url = "http://${cfg.listenAddress}:${toString cfg.listenPort}";
    as_token = cfg.appServiceToken;
    hs_token = cfg.homeserverToken;
    rate_limited = false;
    sender_localpart = "Eg7SOEMJLfuDEgaaEnxKpAKrjT0KOR7f";
    "de.sorunome.msc2409.push_ephemeral" = true;
    push_ephemeral = true;
    namespaces = {
      users = [
        {
          regex = "^@slack_.+:nevarro.space$";
          exclusive = true;
        }
        {
          regex = "^@slackbot:nevarro.space$";
          exclusive = true;
        }
      ];
      aliases = [ ];
      rooms = [ ];
    };
  };

  yamlFormat = pkgs.formats.yaml { };

  mautrixSlackAppserviceConfigYaml =
    yamlFormat.generate "mautrix-slack-registration.yaml"
      mautrixSlackAppserviceConfig;

  mautrixSlackConfig = {
    homeserver = {
      address = cfg.homeserver;
      domain = config.networking.domain;
    };

    metrics = {
      enabled = true;
      listen_port = 9012;
    };

    appservice = {
      address = "http://${cfg.listenAddress}:${toString cfg.listenPort}";
      hostname = cfg.listenAddress;
      port = cfg.listenPort;
      max_body_size = 1;
      database = {
        type = "sqlite3-fk-wal";
        uri = "file:${cfg.dataDir}/mautrix-slack.db?_txlock=immediate";
        max_open_conns = 20;
        max_idle_cons = 2;
      };
      id = "slack";
      bot_username = cfg.botUsername;
      bot_displayname = "Slack bridge bot";
      bot_avatar = "mxc://nevarro.space/yKNWtofJaVLfedQIlAAZbUco";
      as_token = cfg.appServiceToken;
      hs_token = cfg.homeserverToken;
      ephemeral_events = true;
    };

    bridge = {
      username_template = "slack_{{.}}";
      displayname_template = "{{.RealName}} (S)";
      bot_displayname_template = "{{.Name}} (bot)";
      channel_name_template = "#{{.Name}}";
      portal_message_buffer = 128;
      delivery_receipts = true;
      message_error_notices = true;
      federate_rooms = false;
      command_prefix = "!slack";
      backfill = {
        enable = true;
        unread_hours_threshold = -1;
        immediate_messages = 10;
        incremental = {
          messages_per_batch = 100;
          post_batch_delay = 20;
          max_messages = {
            channel = -1;
            group_dm = -1;
            dm = -1;
          };
        };
      };
      encryption = {
        allow = true;
        default = true;
        require = true;
        allow_key_sharing = true;
        verification_levels = {
          receive = "unverified";
          send = "cross-signed-tofu";
          share = "unverified";
        };
      };
      permissions = {
        "nevarro.space" = "user";
        "@sumner:sumnerevans.com" = "admin";
        "@sumner:nevarro.space" = "admin";
      };
    };

    logging = {
      min_level = "debug";
      writers = [{
        type = "stdout";
        format = "json";
      }];
    };
  };

  mautrixSlackConfigYaml =
    yamlFormat.generate "mautrix-slack-config.yaml" mautrixSlackConfig;
in
{
  options = {
    services.mautrix-slack = {
      enable = mkEnableOption "mautrix-slack, a Slack <-> Matrix bridge.";
      useLocalSynapse = mkOption {
        type = types.bool;
        default = true;
        description = "Whether or not to use the local synapse instance.";
      };
      homeserver = mkOption {
        type = types.str;
        default = "http://localhost:8008";
        description = "The URL of the Matrix homeserver.";
      };
      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "The address for mautrix-slack to listen on.";
      };
      listenPort = mkOption {
        type = types.int;
        default = 9891;
        description = "The port for mautrix-slack to listen on.";
      };
      botUsername = mkOption {
        type = types.str;
        default = "slackbot";
        description =
          "The localpart of the mautrix-slack admin bot's username.";
      };
      appServiceToken = mkOption {
        type = types.str;
        description = ''
          This is the token that the app service should use as its access_token
          when using the Client-Server API. This can be anything you want.
        '';
      };
      homeserverToken = mkOption {
        type = types.str;
        description = ''
          This is the token that the homeserver will use when sending requests
          to the app service. This can be anything you want.
        '';
      };
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/mautrix-slack";
      };
      secretYAML = mkOption { type = types.path; };
    };
  };

  config = mkIf cfg.enable {
    meta.maintainers = [ maintainers.sumnerevans ];

    assertions = [{
      assertion = cfg.useLocalSynapse
        -> config.services.matrix-synapse-custom.enable;
      message = ''
        Mautrix-Slack must be running on the same server as Synapse if
        'useLocalSynapse' is enabled.
      '';
    }];

    services.matrix-synapse-custom.appServiceConfigFiles =
      mkIf cfg.useLocalSynapse [ mautrixSlackAppserviceConfigYaml ];

    # Create a user for mautrix-slack.
    users = {
      users.mautrixslack = {
        group = "matrix";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.matrix = { };
    };

    systemd.services.mautrix-slack = {
      description = "Slack <-> Matrix Bridge";
      wantedBy = [ "multi-user.target" ];
      after = [ "appservice_login_shared_secret_yaml-key.service" ]
        ++ optional cfg.useLocalSynapse "matrix-synapse.target";
      preStart = ''
        ${pkgs.yq-go}/bin/yq ea '. as $item ireduce ({}; . * $item )' \
          ${mautrixSlackConfigYaml} ${cfg.secretYAML} > config.yaml
      '';
      serviceConfig = {
        User = "mautrixslack";
        Group = "matrix";
        ExecStart = "${mautrix-slack}/bin/mautrix-slack --no-update";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        SupplementaryGroups = [ "keys" ];
      };
    };

    services.prometheus = {
      enable = true;
      scrapeConfigs = [{
        job_name = "mautrixslack";
        scrape_interval = "15s";
        metrics_path = "/";
        static_configs = [{ targets = [ "0.0.0.0:9012" ]; }];
      }];
    };
  };
}
