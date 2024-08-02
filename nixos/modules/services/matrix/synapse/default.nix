# See: https://nixos.org/nixos/manual/index.html#module-services-matrix-synapse
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.matrix-synapse-custom;

  wrapped = pkgs.matrix-synapse.override {
    extras = [
      "jwt"
      "oidc"
      "postgres"
      "redis"
      "sentry"
      "systemd"
      "url-preview"
      "url-preview"
      "user-search"
      "user-search"
    ];
    plugins = [ pkgs.matrix-synapse-plugins.matrix-synapse-shared-secret-auth ];
  };

  yamlFormat = pkgs.formats.yaml { };

  sharedConfig =
    recursiveUpdate (import ./shared-config.nix ({ inherit config lib pkgs; }))
    cfg.extraConfig;
  sharedConfigFile =
    yamlFormat.generate "matrix-synapse-config.yaml" sharedConfig;

  configFiles = [ sharedConfigFile ]
    ++ optional (cfg.sharedSecretAuthConfigFile != null)
    cfg.sharedSecretAuthConfigFile
    ++ optional (cfg.registrationSharedSecretConfigFile != null)
    cfg.registrationSharedSecretConfigFile;
  configPaths = concatMapStringsSep " " (p: " --config-path ${p} ") configFiles;

  mkSynapseWorkerService = config:
    recursiveUpdate config {
      after = [ "matrix-synapse.service" ];
      partOf = [ "matrix-synapse.target" ];
      wantedBy = [ "matrix-synapse.target" ];
      serviceConfig = {
        Type = "notify";
        User = "matrix-synapse";
        Group = "matrix-synapse";
        WorkingDirectory = cfg.dataDir;
        ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        UMask = "0077";
        SupplementaryGroups = [ "keys" ];
      };
    };

  mkSynapseWorkerConfig = port: config:
    let
      newConfig = {
        # Default to generic worker.
        worker_app = "synapse.app.generic_worker";
      } // config;
      newWorkerListeners = (config.worker_listeners or [ ]) ++ [{
        type = "metrics";
        bind_address = "";
        port = port;
      }];
    in newConfig // { worker_listeners = newWorkerListeners; };

  federationSender1ConfigFile = yamlFormat.generate "federation-sender-1.yaml"
    (mkSynapseWorkerConfig 9101 {
      worker_app = "synapse.app.federation_sender";
      worker_name = "federation_sender1";
    });

  federationSender2ConfigFile = yamlFormat.generate "federation-sender-2.yaml"
    (mkSynapseWorkerConfig 9106 {
      worker_app = "synapse.app.federation_sender";
      worker_name = "federation_sender2";
    });

  federationReader1ConfigFile = yamlFormat.generate "federation-reader-1.yaml"
    (mkSynapseWorkerConfig 9102 {
      worker_name = "federation_reader1";
      worker_listeners = [
        # Federation
        {
          type = "http";
          port = 8009;
          bind_address = "0.0.0.0";
          tls = false;
          x_forwarded = true;
          resources = [{
            names = [ "federation" ];
            compress = false;
          }];
        }
      ];
    });

  eventPersister1ConfigFile = yamlFormat.generate "event-persister-1.yaml"
    (mkSynapseWorkerConfig 9103 {
      worker_name = "event_persister1";
      # The event persister needs a replication listener
      worker_listeners = [{
        type = "http";
        port = 9091;
        bind_address = "127.0.0.1";
        resources = [{ names = [ "replication" ]; }];
      }];
    });

  eventPersister2ConfigFile = yamlFormat.generate "event-persister-2.yaml"
    (mkSynapseWorkerConfig 9107 {
      worker_name = "event_persister2";
      # The event persister needs a replication listener
      worker_listeners = [{
        type = "http";
        port = 9092;
        bind_address = "127.0.0.1";
        resources = [{ names = [ "replication" ]; }];
      }];
    });

  synchotron1ConfigFile = yamlFormat.generate "synchotron-1.yaml"
    (mkSynapseWorkerConfig 9104 {
      worker_name = "synchotron1";
      worker_listeners = [{
        type = "http";
        port = 8010;
        bind_address = "0.0.0.0";
        resources = [{ names = [ "client" ]; }];
      }];
    });

  mediaRepo1ConfigFile = yamlFormat.generate "media-repo-1.yaml"
    (mkSynapseWorkerConfig 9105 {
      worker_name = "media_repo1";
      worker_app = "synapse.app.media_repository";
      worker_listeners = [{
        type = "http";
        port = 8011;
        bind_address = "0.0.0.0";
        resources = [{ names = [ "media" "client" "federation" ]; }];
      }];
    });
in {
  imports = [ ./cleanup-synapse.nix ];

  options = {
    services.matrix-synapse-custom = {
      enable = mkEnableOption "Synapse, the reference Matrix homeserver";

      appServiceConfigFiles = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = ''
          A list of application service config file to use.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/matrix-synapse";
        description = ''
          The directory where matrix-synapse stores its stateful data such as
          certificates, media and uploads.
        '';
      };

      registrationSharedSecretConfigFile = mkOption {
        type = with types; nullOr path;
        default = null;
        description = ''
          The path to a file that contains the shared registration secret.
        '';
      };

      sharedSecretAuthConfigFile = mkOption {
        type = with types; nullOr path;
        default = null;
        description = ''
          The path to a file that contains the shared secret auth secret.
        '';
      };

      extraConfig = mkOption {
        type = yamlFormat.type;
        default = { };
      };
    };
  };

  config = mkIf cfg.enable {
    # Create a user and group for Synapse
    users.users.matrix-synapse = {
      group = "matrix-synapse";
      home = cfg.dataDir;
      createHome = true;
      shell = "${pkgs.bash}/bin/bash";
      uid = config.ids.uids.matrix-synapse;
    };

    users.groups.matrix-synapse = { gid = config.ids.gids.matrix-synapse; };

    systemd.targets.matrix-synapse = {
      description = "Synapse processes";
      requires = [ "network.target" "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    # Run the main Synapse process
    systemd.services.matrix-synapse = {
      description = "Synapse Matrix homeserver";
      partOf = [ "matrix-synapse.target" ];
      wantedBy = [ "matrix-synapse.target" ];
      preStart = ''
        ${wrapped}/bin/synapse_homeserver \
          ${configPaths} \
          --keys-directory ${cfg.dataDir} \
          --generate-keys
      '';
      serviceConfig = {
        Type = "notify";
        User = "matrix-synapse";
        Group = "matrix-synapse";
        WorkingDirectory = cfg.dataDir;
        ExecStartPre = [
          ("+" + (pkgs.writeShellScript "matrix-synapse-fix-permissions" ''
            chown matrix-synapse:matrix-synapse ${cfg.dataDir}/homeserver.signing.key
            chmod 0600 ${cfg.dataDir}/homeserver.signing.key
          ''))
        ];
        ExecStart = ''
          ${wrapped}/bin/synapse_homeserver \
            ${configPaths} \
            --keys-directory ${cfg.dataDir}
        '';
        ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        UMask = "0077";
        SupplementaryGroups = [ "keys" ];
      };
    };

    # Run the federation sender worker
    systemd.services.matrix-synapse-federation-sender1 =
      mkSynapseWorkerService {
        description = "Synapse Matrix federation sender 1";
        serviceConfig.ExecStart = ''
          ${wrapped}/bin/synapse_worker \
            ${configPaths} \
            --config-path ${federationSender1ConfigFile} \
            --keys-directory ${cfg.dataDir}
        '';
      };

    systemd.services.matrix-synapse-federation-sender2 =
      mkSynapseWorkerService {
        description = "Synapse Matrix federation sender 2";
        serviceConfig.ExecStart = ''
          ${wrapped}/bin/synapse_worker \
            ${configPaths} \
            --config-path ${federationSender2ConfigFile} \
            --keys-directory ${cfg.dataDir}
        '';
      };

    # Run the federation reader worker
    systemd.services.matrix-synapse-federation-reader1 =
      mkSynapseWorkerService {
        description = "Synapse Matrix federation reader 1";
        serviceConfig.ExecStart = ''
          ${wrapped}/bin/synapse_worker \
            ${configPaths} \
            --config-path ${federationReader1ConfigFile} \
            --keys-directory ${cfg.dataDir}
        '';
      };

    # Run the event persister worker
    systemd.services.matrix-synapse-event-persister1 = mkSynapseWorkerService {
      description = "Synapse Matrix event persister 1";
      serviceConfig.ExecStart = ''
        ${wrapped}/bin/synapse_worker \
          ${configPaths} \
          --config-path ${eventPersister1ConfigFile} \
          --keys-directory ${cfg.dataDir}
      '';
    };

    systemd.services.matrix-synapse-event-persister2 = mkSynapseWorkerService {
      description = "Synapse Matrix event persister 2";
      serviceConfig.ExecStart = ''
        ${wrapped}/bin/synapse_worker \
          ${configPaths} \
          --config-path ${eventPersister2ConfigFile} \
          --keys-directory ${cfg.dataDir}
      '';
    };

    # Run the synchotron worker
    systemd.services.matrix-synapse-synchotron1 = mkSynapseWorkerService {
      description = "Synapse Matrix synchotron 1";
      serviceConfig.ExecStart = ''
        ${wrapped}/bin/synapse_worker \
          ${configPaths} \
          --config-path ${synchotron1ConfigFile} \
          --keys-directory ${cfg.dataDir}
      '';
    };

    # Run the media repo worker
    systemd.services.matrix-synapse-media-repo1 = mkSynapseWorkerService {
      description = "Synapse Matrix media repo 1";
      serviceConfig.ExecStart = ''
        ${wrapped}/bin/synapse_worker \
          ${configPaths} \
          --config-path ${mediaRepo1ConfigFile} \
          --keys-directory ${cfg.dataDir}
      '';
    };

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

    # Run the sliding-sync proxy.
    services.matrix-sliding-sync = {
      enable = true;
      createDatabase = true;
      environmentFile = "/run/keys/nevarro_space_sliding_sync_environment_file";
      settings = {
        SYNCV3_SERVER = "https://matrix.nevarro.space";
        SYNCV3_BINDADDR = "0.0.0.0:8012";
      };
    };

    # Ensure that Redis is setup for Synapse.
    services.redis.servers."".enable = true;

    # Allow scraping of prom metrics
    networking.firewall.allowedTCPPorts =
      [ 9009 9101 9106 9102 9103 9107 9104 9105 ];

    # Set up nginx to forward requests properly.
    services.nginx = {
      enable = true;
      virtualHosts = {
        # Reverse proxy for Matrix client-server and server-server communication
        "matrix.${config.networking.domain}" = {
          enableACME = true;
          forceSSL = true;

          # If they access root, redirect to Element. If they access the API, then
          # forward on to Synapse.
          locations."/".return = "301 https://${config.networking.domain}";
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
          locations."~ ^/(_matrix/media|_matrix/client/v1/media|_synapse/admin/v1/(purge_media_cache|(room|user)/.*/media.*|media/.*|quarantine_media/.*|users/.*/media))" =
            {
              proxyPass = "http://0.0.0.0:8011"; # without a trailing /
              extraConfig = ''
                access_log /var/log/nginx/matrix-media-repo.access.log;
              '';
            };
        };

        "syncv3.${config.networking.domain}" = {
          enableACME = true;
          forceSSL = true;

          locations."/".return = "301 https://${config.networking.domain}";
          locations."/_matrix" = {
            proxyPass = "http://0.0.0.0:8012"; # without a trailing /
            extraConfig = ''
              access_log /var/log/nginx/matrix.access.log;
            '';
          };
        };
      };
    };

    # Add a backup service.
    services.backup.backups.matrix = {
      path = config.services.matrix-synapse.dataDir;
    };
  };
}
