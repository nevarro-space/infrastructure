{ config, lib, pkgs, ... }:
let
  synapse-http-antispam =
    pkgs.callPackage ../../../pkgs/synapse-http-antispam.nix { };
in lib.mkIf config.services.matrix-synapse.enable {
  services.matrix-synapse = {
    configureRedisLocally = true; # Required for workers
    plugins = [
      pkgs.matrix-synapse-plugins.matrix-synapse-shared-secret-auth
      synapse-http-antispam
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
          path = "/run/matrix-synapse/main_replication.sock";
          type = "http";
          resources = [{
            names = [ "replication" ];
            compress = false;
          }];
        }
        {
          port = 9009;
          bind_addresses = [ "127.0.0.1" ];
          tls = false;
          type = "metrics";
          resources = [{ names = [ "metrics" ]; }];
        }
      ];

      # Media
      # TODO move to media_store to match state version
      media_store_path = "${config.services.matrix-synapse.dataDir}/media";
      max_upload_size = "100M";
      enable_media_repo = false; # Disable media repo on the master worker
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
      turn_shared_secret =
        "n0t4ctuAllymatr1Xd0TorgSshar3d5ecret4obvIousreAsons";
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

      federation_sender_instances =
        [ "federation_sender1" "federation_sender2" ];
      stream_writers.events = [ "event_persister1" "event_persister2" ];

      instance_map = let
        mkInstance = port: {
          inherit port;
          host = "localhost";
        };
      in {
        "federation_sender1" = mkInstance 9093;
        "federation_sender2" = mkInstance 9094;
        "event_persister1" = mkInstance 9091;
        "event_persister2" = mkInstance 9092;
      };
    };

    workers = let
      mkMetricsListener = port: {
        inherit port;
        type = "metrics";
        bind_addresses = [ "127.0.0.1" ];
        resources = [{ names = [ "metrics" ]; }];
      };
      mkReplicationListener = port: {
        inherit port;
        type = "http";
        bind_addresses = [ "127.0.0.1" ];
        resources = [{ names = [ "replication" ]; }];
      };
    in {
      "federation_sender1".worker_listeners =
        [ (mkMetricsListener 9101) (mkReplicationListener 9093) ];
      "federation_sender2".worker_listeners =
        [ (mkMetricsListener 9106) (mkReplicationListener 9094) ];
      "federation_reader1".worker_listeners = [
        (mkMetricsListener 9102)
        {
          type = "http";
          port = 8009;
          bind_addresses = [ "127.0.0.1" ];
          tls = false;
          x_forwarded = true;
          resources = [{ names = [ "federation" ]; }];
        }
      ];
      "event_persister1".worker_listeners =
        [ (mkMetricsListener 9103) (mkReplicationListener 9091) ];
      "event_persister2".worker_listeners =
        [ (mkMetricsListener 9107) (mkReplicationListener 9092) ];
      "synchotron1".worker_listeners = [
        (mkMetricsListener 9104)
        {
          type = "http";
          port = 8010;
          bind_addresses = [ "127.0.0.1" ];
          x_forwarded = true;
          resources = [{ names = [ "client" ]; }];
        }
      ];
      "media_repo1" = {
        worker_app = "synapse.app.media_repository";
        worker_listeners = [
          (mkMetricsListener 9105)
          {
            type = "http";
            port = 8011;
            bind_addresses = [ "127.0.0.1" ];
            x_forwarded = true;
            resources = [{ names = [ "media" "client" "federation" ]; }];
          }
        ];
      };
    };
  };

  # Allow the services to access the keys
  systemd.services = let
    services = [ "matrix-synapse" ]
      ++ (lib.mapAttrsToList (name: _: "matrix-synapse-worker-${name}")
        config.services.matrix-synapse.workers);
  in builtins.listToAttrs (map (name: {
    inherit name;
    value = { serviceConfig.SupplementaryGroups = [ "keys" "meowlnir" ]; };
  }) services);

  # Allow scraping of prom metrics
  networking.firewall.allowedTCPPorts =
    [ 9009 9101 9106 9102 9103 9107 9104 9105 ];

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
    virtualHosts = let
      mediaRepoLocation = {
        priority = 0; # media repo needs to be before federation
        proxyPass = "http://0.0.0.0:8011"; # without a trailing /
        extraConfig = ''
          access_log /var/log/nginx/matrix-media-repo.access.log;
        '';
      };
    in {
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
        locations."/_matrix/federation/" = {
          proxyPass = "http://0.0.0.0:8009"; # without a trailing /
          extraConfig = ''
            access_log /var/log/nginx/matrix-federation.access.log;
          '';
        };
        locations."~ ^/_matrix/client/.*/(sync|events|initialSync)" = {
          proxyPass = "http://0.0.0.0:8010"; # without a trailing /
          extraConfig = ''
            access_log /var/log/nginx/matrix-synchotron.access.log;
          '';
        };

        # Media locations
        locations."~ ^/_matrix/media/" = mediaRepoLocation;
        locations."~ ^/_matrix/client/.*/media/" = mediaRepoLocation;
        locations."~ ^/_matrix/federation/.*/media/" = mediaRepoLocation;
        locations."~ ^/_synapse/admin/v1/(purge_media_cache|(room|user)/.*/media.*|media/.*|quarantine_media/.*|users/.*/media)" =
          mediaRepoLocation;

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
