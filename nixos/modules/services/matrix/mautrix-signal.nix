{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.mautrix-signal;

  mautrix-signal = pkgs.callPackage ../../../pkgs/mautrix-signal.nix { };

  mautrixSignalAppserviceConfig = {
    id = "signal";
    url = "http://${cfg.listenAddress}:${toString cfg.listenPort}";
    as_token = cfg.appServiceToken;
    hs_token = cfg.homeserverToken;
    rate_limited = false;
    sender_localpart = "aAcrX48XZTC9x240XrJm4E1CVGGaMcog";
    "de.sorunome.msc2409.push_ephemeral" = true;
    push_ephemeral = true;
    namespaces = {
      users = [
        {
          regex = "^@signal_.+:nevarro.space$";
          exclusive = true;
        }
        {
          regex = "^@signalbot:nevarro.space$";
          exclusive = true;
        }
      ];
      aliases = [ ];
      rooms = [ ];
    };
  };

  yamlFormat = pkgs.formats.yaml { };

  mautrixSignalAppserviceConfigYaml =
    yamlFormat.generate "mautrix-signal-registration.yaml"
    mautrixSignalAppserviceConfig;

  mautrixSignalConfig = {
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
        uri = "file:${cfg.dataDir}/mautrix-signal.db?_txlock=immediate";
        max_open_conns = 20;
        max_idle_cons = 2;
      };
      id = "signal";
      bot_username = cfg.botUsername;
      bot_displayname = "Signal bridge bot";
      bot_avatar = "mxc://nevarro.space/xKXcxnzKjRsvnqQiibxMLVVO";
      as_token = cfg.appServiceToken;
      hs_token = cfg.homeserverToken;
      ephemeral_events = true;
    };

    bridge = {
      username_template = "signal_{{.}}";
      displayname_template =
        ''{{or .ContactName .ProfileName .PhoneNumber "Unknown user"}}'';
      portal_message_buffer = 128;
      personal_filtering_spaces = true;
      delivery_receipts = true;
      use_contact_avatars = true;
      message_error_notices = true;
      federate_rooms = false;
      command_prefix = "!signal";
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

  mautrixSignalConfigYaml =
    yamlFormat.generate "mautrix-signal-config.yaml" mautrixSignalConfig;
in {
  options = {
    services.mautrix-signal = {
      enable = mkEnableOption "mautrix-signal, a Signal <-> Matrix bridge.";
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
        description = "The address for mautrix-signal to listen on.";
      };
      listenPort = mkOption {
        type = types.int;
        default = 9892;
        description = "The port for mautrix-signal to listen on.";
      };
      botUsername = mkOption {
        type = types.str;
        default = "signalbot";
        description =
          "The localpart of the mautrix-signal admin bot's username.";
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
        default = "/var/lib/mautrix-signal";
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
        Mautrix-Signal must be running on the same server as Synapse if
        'useLocalSynapse' is enabled.
      '';
    }];

    services.matrix-synapse-custom.appServiceConfigFiles =
      mkIf cfg.useLocalSynapse [ mautrixSignalAppserviceConfigYaml ];

    # Create a user for mautrix-signal.
    users = {
      users.mautrixsignal = {
        group = "matrix";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.matrix = { };
    };

    systemd.services.mautrix-signal = {
      description = "Signal <-> Matrix Bridge";
      wantedBy = [ "multi-user.target" ];
      after = [ "appservice_login_shared_secret_yaml-key.service" ]
        ++ optional cfg.useLocalSynapse "matrix-synapse.target";
      preStart = ''
        ${pkgs.yq-go}/bin/yq ea '. as $item ireduce ({}; . * $item )' \
          ${mautrixSignalConfigYaml} ${cfg.secretYAML} > config.yaml
      '';
      serviceConfig = {
        User = "mautrixsignal";
        Group = "matrix";
        ExecStart = "${mautrix-signal}/bin/mautrix-signal --no-update";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        SupplementaryGroups = [ "keys" ];
      };
    };

    services.prometheus = {
      enable = true;
      scrapeConfigs = [{
        job_name = "mautrixsignal";
        scrape_interval = "15s";
        metrics_path = "/";
        static_configs = [{ targets = [ "0.0.0.0:9012" ]; }];
      }];
    };
  };
}
