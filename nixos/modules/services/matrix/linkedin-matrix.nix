{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.linkedin-matrix;

  linkedin-matrix = pkgs.callPackage ../../../pkgs/linkedin-matrix.nix { };

  linkedinMatrixAppserviceConfig = {
    id = "linkedin";
    url = "http://${cfg.listenAddress}:${toString cfg.listenPort}";
    as_token = cfg.appServiceToken;
    hs_token = cfg.homeserverToken;
    rate_limited = false;
    sender_localpart =
      "XDUsekmAmWcmL1FWrgZ8E7ih-p0vffI3kMiezV43Sw29GLBQAQ-0_GRJXMQXlVb0";
    "de.sorunome.msc2409.push_ephemeral" = true;
    push_ephemeral = true;
    namespaces = {
      users = [
        {
          regex = "@li_.*:nevarro.space";
          exclusive = true;
        }
        {
          regex = "@linkedinbot:nevarro.space";
          exclusive = true;
        }
      ];
      aliases = [ ];
      rooms = [ ];
    };
  };

  yamlFormat = pkgs.formats.yaml { };

  linkedinMatrixAppserviceConfigYaml =
    yamlFormat.generate "linkedin-matrix-registration.yaml"
    linkedinMatrixAppserviceConfig;

  linkedinMatrixConfig = {
    homeserver = {
      address = cfg.homeserver;
      domain = config.networking.domain;
      verify_ssl = false;
      asmux = false;
      http_retry_count = 4;
    };

    metrics = {
      enabled = true;
      listen_port = 9010;
    };

    appservice = {
      address = "http://${cfg.listenAddress}:${toString cfg.listenPort}";
      hostname = cfg.listenAddress;
      port = cfg.listenPort;
      max_body_size = 1;
      database =
        "postgresql://linkedinmatrix:linkedinmatrix@localhost/linkedin-matrix";
      database_opts = {
        min_size = 5;
        max_size = 10;
      };
      id = "linkedin";
      bot_username = cfg.botUsername;
      bot_displayname = "LinkedIn bridge bot";
      bot_avatar = "mxc://sumnerevans.com/XMtwdeUBnxYvWNFFrfeTSHqB";
      as_token = cfg.appServiceToken;
      hs_token = cfg.homeserverToken;
      ephemeral_events = true;
    };

    bridge = {
      username_template = "li_{userid}";
      displayname_template = "{displayname}";
      displayname_preference = [ "name" "first_name" ];
      set_topic_on_dms = true;
      command_prefix = "!li";
      initial_chat_sync = 20;
      invite_own_puppet_to_pm = false;
      sync_with_custom_puppets = false;
      sync_direct_chat_list = true;
      space_support = {
        enable = true;
        name = "LinkedIn";
      };
      presence = false;
      update_avatar_initial_sync = true;
      federate_rooms = false;
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
      delivery_receipts = true;
      backfill = {
        invite_own_puppet = true;
        initial_limit = 20;
        missed_limit = 20;
        disable_notifications = true;
      };
      temporary_disconnect_notices = true;
      mute_bridging = true;
      permissions = {
        "nevarro.space" = "user";
        "@sumner:sumnerevans.com" = "admin";
        "@sumner:nevarro.space" = "admin";
      };
    };

    logging = {
      version = 1;

      formatters.journal_fmt.format = "[%(name)s] %(message)s";
      handlers = {
        journal = {
          class = "systemd.journal.JournalHandler";
          formatter = "journal_fmt";
          SYSLOG_IDENTIFIER = "linkedin-matrix";
        };
      };
      loggers = {
        aiohttp.level = "DEBUG";
        mau.level = "DEBUG";
        paho.level = "DEBUG";
        root.level = "DEBUG";
      };
      root = {
        level = "DEBUG";
        handlers = [ "journal" ];
      };
    };
  };

  linkedinMatrixConfigYaml =
    yamlFormat.generate "linkedin-config.yaml" linkedinMatrixConfig;
in {
  options = {
    services.linkedin-matrix = {
      enable = mkEnableOption
        "linkedin-matrix, a LinkedIn Messaging <-> Matrix bridge";
      useLocalSynapse = mkOption {
        type = types.bool;
        default = true;
        description = "Whether or not to use the local synapse instance.";
      };
      homeserver = mkOption {
        type = types.str;
        description = "The URL of the Matrix homeserver.";
      };
      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "The address for linkedin-matrix to listen on.";
      };
      listenPort = mkOption {
        type = types.int;
        default = 9899;
        description = "The port for linkedin-matrix to listen on.";
      };
      botUsername = mkOption {
        type = types.str;
        default = "linkedinbot";
        description =
          "The localpart of the linkedin-matrix admin bot's username.";
      };
      secretYAML = mkOption { type = types.path; };
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/linkedin-matrix";
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
    };
  };

  config = mkIf cfg.enable {
    meta.maintainers = [ maintainers.sumnerevans ];

    assertions = [{
      assertion = cfg.useLocalSynapse -> config.services.matrix-synapse.enable;
      message = ''
        LinkedIn must be running on the same server as Synapse if
        'useLocalSynapse' is enabled.
      '';
    }];

    services.matrix-synapse.settings.app_service_config_files =
      mkIf cfg.useLocalSynapse [ linkedinMatrixAppserviceConfigYaml ];

    # Create a user for linkedin-matrix.
    users.users.linkedinmatrix = {
      group = "matrix";
      isSystemUser = true;
      home = cfg.dataDir;
      createHome = true;
    };
    users.groups.matrix = { };

    # Create a database user for linkedin-matrix
    services.postgresql.ensureDatabases = [ "linkedin-matrix" ];
    services.postgresql.ensureUsers = [{ name = "linkedinmatrix"; }];

    systemd.services.linkedin-matrix = {
      description = "LinkedIn Messaging <-> Matrix Bridge";
      requires = [ "appservice_login_shared_secret_yaml-key.service" ]
        ++ optional cfg.useLocalSynapse "matrix-synapse.target";
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ${pkgs.yq-go}/bin/yq ea '. as $item ireduce ({}; . * $item )' \
          ${linkedinMatrixConfigYaml} ${cfg.secretYAML} > config.yaml
      '';
      serviceConfig = {
        User = "linkedinmatrix";
        Group = "matrix";
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${linkedin-matrix}/bin/linkedin-matrix --no-update";
        Restart = "on-failure";
        SupplementaryGroups = [ "keys" ];
      };
    };

    # TODO this probably doesn't work
    services.prometheus = {
      enable = true;
      scrapeConfigs = [{
        job_name = "linkedinmatirx";
        scrape_interval = "15s";
        metrics_path = "/";
        static_configs = [{ targets = [ "0.0.0.0:9010" ]; }];
      }];
    };
  };
}
