{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.mautrix-discord;

  mautrixDiscordAppserviceConfig = {
    id = "discord";
    url = "http://${cfg.listenAddress}:${toString cfg.listenPort}";
    as_token = cfg.appServiceToken;
    hs_token = cfg.homeserverToken;
    rate_limited = false;
    sender_localpart = "LI6W2mH43X68rSiZ1YLAQCSLtuSZlPBt";
    "de.sorunome.msc2409.push_ephemeral" = true;
    push_ephemeral = true;
    namespaces = {
      users = [
        {
          regex = "^@discord_[0-9]+:nevarro.space$";
          exclusive = true;
        }
        {
          regex = "^@discordbot:nevarro.space$";
          exclusive = true;
        }
      ];
      aliases = [ ];
      rooms = [ ];
    };
  };

  yamlFormat = pkgs.formats.yaml { };

  mautrixDiscordAppserviceConfigYaml =
    yamlFormat.generate "mautrix-discord-registration.yaml"
    mautrixDiscordAppserviceConfig;

  mautrixDiscordConfig = {
    homeserver = {
      address = cfg.homeserver;
      domain = config.networking.domain;
    };

    metrics = {
      enabled = true;
      listen_port = 9011;
    };

    appservice = {
      address = "http://${cfg.listenAddress}:${toString cfg.listenPort}";
      hostname = cfg.listenAddress;
      port = cfg.listenPort;
      max_body_size = 1;
      database = {
        type = "sqlite3-fk-wal";
        uri = "file:${cfg.dataDir}/mautrix-discord.db?_txlock=immediate";
        max_open_conns = 20;
        max_idle_cons = 2;
      };
      id = "discord";
      bot_username = cfg.botUsername;
      bot_displayname = "Discord bridge bot";
      bot_avatar = "mxc://nevarro.space/LWsPMGFektATJpgbSyfULDKR";
      as_token = cfg.appServiceToken;
      hs_token = cfg.homeserverToken;
      ephemeral_events = true;
    };

    bridge = {
      username_template = "discord_{{.}}";
      displayname_template =
        "{{or .GlobalName .Username}}{{if .Bot}} (bot){{end}}";
      channel_name_template =
        "{{if or (eq .Type 3) (eq .Type 4)}}{{.Name}}{{else}}#{{.Name}}{{end}}";
      guild_name_template = "{{.Name}}";
      private_chat_portal_meta = false;
      portal_message_buffer = 128;
      startup_private_channel_create_limit = 5;
      delivery_receipts = true;
      message_error_notices = true;
      restricted_rooms = true;
      delete_portal_on_channel_delete = true;
      federate_rooms = false;
      command_prefix = "!dis";
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
        "@sumner:nevarro.space" = "admin";
      };
      direct_media = {
        enabled = true;
        server_name = "discord-media.nevarro.space";
        server_key =
          "ed25519 Eh81nA EkQgQPrpncdecK1Yh/Is7H1iII1ibn67CZFWhleEkh0";
      };
      login_shared_secret_map = {
        "nevarro.space" = "as_token:${cfg.appServiceToken}";
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

  mautrixDiscordConfigYaml =
    yamlFormat.generate "mautrix-discord-config.yaml" mautrixDiscordConfig;
in {
  options = {
    services.mautrix-discord = {
      enable = mkEnableOption "mautrix-discord, a Discord <-> Matrix bridge.";
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
        description = "The address for mautrix-discord to listen on.";
      };
      listenPort = mkOption {
        type = types.int;
        default = 9890;
        description = "The port for mautrix-discord to listen on.";
      };
      botUsername = mkOption {
        type = types.str;
        default = "discordbot";
        description =
          "The localpart of the mautrix-discord admin bot's username.";
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
        default = "/var/lib/mautrix-discord";
      };
    };
  };

  config = mkIf cfg.enable {
    meta.maintainers = [ maintainers.sumnerevans ];

    assertions = [{
      assertion = cfg.useLocalSynapse -> config.services.matrix-synapse.enable;
      message = ''
        Mautrix-Discord must be running on the same server as Synapse if
        'useLocalSynapse' is enabled.
      '';
    }];

    services.matrix-synapse.settings.app_service_config_files =
      mkIf cfg.useLocalSynapse [ mautrixDiscordAppserviceConfigYaml ];

    # Create a user for mautrix-discord.
    users = {
      users.mautrixdiscord = {
        group = "matrix";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.matrix = { };
    };

    services.nginx = {
      enable = true;

      virtualHosts."discord-media.nevarro.space" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://${cfg.listenAddress}:${toString cfg.listenPort}";
          extraConfig = ''
            access_log /var/log/nginx/mautrix-discord.access.log;
          '';
        };
      };
    };

    systemd.services.mautrix-discord = {
      description = "Discord <-> Matrix Bridge";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ] ++ optional cfg.useLocalSynapse config.services.matrix-synapse.serviceUnit;
      after = [ "network-online.target" ] ++ optional cfg.useLocalSynapse config.services.matrix-synapse.serviceUnit;
      requires = [ "network-online.target" ] ++ optional cfg.useLocalSynapse config.services.matrix-synapse.serviceUnit;
      serviceConfig = {
        User = "mautrixdiscord";
        Group = "matrix";
        ExecStart = "${pkgs.mautrix-discord}/bin/mautrix-discord --no-update";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        SupplementaryGroups = [ "keys" ];
      };
    };

    # TODO make this work
    services.prometheus = {
      enable = true;
      scrapeConfigs = [{
        job_name = "mautrixdiscord";
        scrape_interval = "15s";
        metrics_path = "/";
        static_configs = [{ targets = [ "0.0.0.0:9011" ]; }];
      }];
    };

    # Add a backup service.
    services.backup.backups.mautrix-discord = { path = cfg.dataDir; };
  };
}
