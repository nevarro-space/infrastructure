{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.services.matrix-synapse.enable {
  services.matrix-synapse = {
    plugins = [
      pkgs.matrix-synapse-plugins.matrix-synapse-shared-secret-auth
      pkgs.matrix-synapse-plugins.synapse-http-antispam
    ];
    extraConfigFiles = [
      "/run/keys/nevarro_space_registration_shared_secret"
      "/run/keys/module_config"
    ];
    log = {
      version = 1;
      disable_existing_loggers = false;
      formatters.journal_fmt.format = "%(name)s: [%(request)s] %(message)s";
      filters.context = {
        "()" = "synapse.util.logcontext.LoggingContextFilter";
        request = "";
      };
      handlers.journal = {
        class = "systemd.journal.JournalHandler";
        formatter = "journal_fmt";
        filters = [ "context" ];
        SYSLOG_IDENTIFIER = "synapse";
      };
      root = {
        level = "INFO";
        handlers = [ "journal" ];
      };
      loggers = {
        shared_secret_authenticator = {
          level = "INFO";
          handlers = [ "journal" ];
        };
      };
    };

    settings = {
      database = {
        name = "psycopg2";
        args = {
          user = "matrix-synapse";
          database = "matrix-synapse";
        };
      };

      # MSC2815 (allow room moderators to view redacted event content)
      experimental_features.msc2815_enabled = true;

      # Registration
      enable_registration = true;
      registration_requires_token = true;

      # Metrics
      enable_metrics = true;
      report_stats = true;
      listeners = [
        {
          port = 8008;
          bind_addresses = [ "127.0.0.1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [ "client" ];
              compress = true;
            }
            {
              names = [ "federation" ];
              compress = false;
            }
          ];
        }
        {
          port = 9009;
          bind_addresses = [ "0.0.0.0" ];
          tls = false;
          type = "metrics";
          resources = [ { names = [ "metrics" ]; } ];
        }
      ];

      # Media
      # TODO move to media_store to match state version
      media_store_path = "${config.services.matrix-synapse.dataDir}/media";
      max_upload_size = "100M";
      enable_media_repo = true;
      enable_authenticated_media = true;
      media_retention.remote_media_lifetime = "90d";

      # Server
      presence.enabled = false;
      public_baseurl = "https://matrix.nevarro.space";
      server_name = "nevarro.space";
      suppress_key_server_warning = true;

      # TURN
      # Configure coturn to point at the matrix.org servers.
      # TODO actually figure this out eventually
      turn_uris = [
        "turn:turn.matrix.org?transport=udp"
        "turn:turn.matrix.org?transport=tcp"
      ];
      turn_shared_secret = "n0t4ctuAllymatr1Xd0TorgSshar3d5ecret4obvIousreAsons";
      turn_user_lifetime = "1h";

      # URL Previews
      url_preview_url_blacklist = [
        {
          username = "*"; # blacklist any URL with a username in its URI
        }

        # Don't preview some work URLs
        { netloc = "linear.app"; }
        { netloc = "^admin.beeper(|-dev|-staging).com$"; }
      ];

      # Caching
      event_cache_size = "25K";
      caches.global_factor = 1.0;

    };

  };

  # Allow the service to access the keys
  systemd.services.matrix-synapse.serviceConfig.SupplementaryGroups = [
    "keys"
    "meowlnir"
  ];

  # Allow scraping of prom metrics
  networking.firewall.allowedTCPPorts = [ 9009 ];

  # Make sure that Postgres is setup for Synapse.
  services.postgresql = {
    enable = true;
    initialScript = pkgs.writeText "synapse-init.sql" ''
      CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
      CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
        TEMPLATE template0
        LC_COLLATE = "C"
        LC_CTYPE = "C";
    '';
  };

  # Set up nginx to forward requests properly.
  services.nginx = {
    enable = true;
    virtualHosts = {
      # Reverse proxy for Matrix client-server and server-server communication
      "matrix.nevarro.space" = {
        enableACME = true;
        forceSSL = true;

        # If they access root, redirect to nevarro.space. If they access the
        # API, then forward on to Synapse.
        locations."/".return = "301 https://nevarro.space";
        locations."/_matrix" = {
          proxyPass = "http://0.0.0.0:8008"; # without a trailing /
          extraConfig = ''
            access_log /var/log/nginx/matrix.access.log;
          '';
        };

        # Event reporting locations
        locations."~ ^/_matrix/client/v3/rooms/.*/report/.*" = {
          proxyPass = config.services.meowlnir.settings.meowlnir.address;
        };
        locations."~ ^/_matrix/client/v3/users/.*/report" = {
          proxyPass = config.services.meowlnir.settings.meowlnir.address;
        };
      };
    };
  };

  # Add a backup service.
  services.backup.backups.matrix = {
    path = config.services.matrix-synapse.dataDir;
  };
}
