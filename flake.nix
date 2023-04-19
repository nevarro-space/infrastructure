{
  description = "Nevarro Infrastructure NixOS deployments";
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs-unstable, ... }: {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs-unstable {
          system = "x86_64-linux";
        };
        description = "Nevarro Infrastructure";
      };

      defaults = { config, lib, pkgs, ... }: {
        system.stateVersion = "23.05";

        boot = {
          loader.grub.device = "/dev/sda";
          initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
          initrd.kernelModules = [ "nvme" ];
          cleanTmpDir = true;
          loader.timeout = 10;

          # Enable LISH
          kernelParams = [ "console=ttyS0,19200n8" ];
          loader.grub.extraConfig = ''
            serial --speed=19200 --unit=0 --word=8 --party=no --stop=1;
            terminal_input serial;
            terminal_output serial;
          '';
        };

        security.acme = {
          defaults.email = "admin@nevarro.space";
          acceptTerms = true;
        };

        services.prometheus.exporters = {
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
            port = 9002;
          };
        };

        services.promtail = {
          enable = true;
          configuration = {
            server = {
              http_listen_port = 28183;
              grpc_listen_port = 0;
            };
            positions.filename = "/tmp/positions.yaml";
            clients = [
              { url = "http://10.0.1.2:3100/loki/api/v1/push"; }
            ];
            scrape_configs = [
              {
                job_name = "journal";
                journal = {
                  max_age = "12h";
                  labels = {
                    job = "systemd-journal";
                    host = config.networking.hostName;
                  };
                };
                relabel_configs = [
                  { source_labels = [ "__journal__systemd_unit" ]; target_label = "unit"; }
                ];
              }
            ];
          };
        };

        networking.firewall.allowedTCPPorts = [ 9002 ];

        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = "prohibit-password";

        networking.domain = "nevarro.space";
        networking.interfaces.eth0.useDHCP = true;

        fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };

        time.timeZone = "America/Denver";

        nix.gc.automatic = true;

        swapDevices = [
          { device = "/var/swapfile"; size = 4096; }
        ];

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3oHcGiwPtWbee1x+6rKdovw4/CNIyE6MbBqC+irqZnyBLchboLKF+n9Vw9XRZxBPHppcb57oUTjh4gFA8N2vKqjVIacMNHSGFhRXBfUYtaTnmhzNj8sFWPwWpYAneTEe0hFdDKhL63nHZsi3XySh7R+BEIFZrDeyvKH86/GRpQwepVpQV3giqtqDA4GVgla/Zcea5ES1uxEolgDQKszXv8Z8iRUnrohrSAgsanjw6B+41X4qrwVnsStYhVN42tT8I7BM6kko9bdsLf4bg/WqdYDwPA4cbg1RkppqI0k7eBXPNfyaUKquiWz6tmrX5IMeIejjV+2BHgu0Q0iweMtPy41DGX6MaaKawWx5hoLds8fszVK02GUoCee26B8oEX+3TGKF9gj62gDcBOEmjLaGjxFrnk/DEkm3zSahwaIjxsbLK0/tFLh5B9Bha5mNF7tU88JwwJl+Zh3R7vGzHTqfZ7XVvSVSfpOPpVm0q3RSHMvVPSulOI+pTbA6GAQn0dT8= sumner@tatooine"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDasJXb4uvxPh0Z1NLa22dTx42VdWD+utRMbK0WeXS6XakIipx1YPb4yqbtUMJkoTLuFW/BUAEXSiks+ARD3Lc4K/iJeHHXbYvgklvr5dAPV6P2KtiVRZ+ipSLv1TF+al6hVUAnp4PPUQTv+3ZRA64QFrCAt26A7OnxKlowyW2KZVSqAcWPdQEbCdwILRCRIWTpbSj1rDeEsnvmu1G+Id5v7+uybQ+twBHbGpfYH7yWYLEhDtRyYu5SgnBcEh0bqszEgt+iLH/XzTQJILKdDaf4x8j/FJ9Px7+VQVfc+yADZ882ZsFzaxlmn7ndstAssmSSsHfRmNye0exIJqGXdxUfpF3w4h5qnR/0AJM7ljtXuDNOlOxflX0WvZinhhOJ/gF3No8sCXG/OcqlMNyrWd+vpJH4f9Xa0PTOn3Qpltq3YxWOZrWopUIDZw5jSsgLpLfC2NtGE/p5nEFnJCmMqrXPDY7dYS+65qYYjWXCzY3d9i3offwIQtV780Gu1VvT/zE= sumner@coruscant"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvBSffkOjq5nzFczPgaC41D5/6w1g1bK94YAAY4mBMVF8wh3aQF62X7FfV4cHM6wgUe2IOWinPZ/imL9+Nu9TsQbGc+mbfLltmZiGiHLqQBJOjMwwodxdkljhPmwUvALemyNiHkJ2yAvnMqSBteJuAv8ayqyYAPbWfRD6zA2N+haHQCSXXqjJTe/rH6ax0rvMWefCxVKKTuxXTfrRSbtGeCB/4QkpJErrItJxYEIkM3/uM4tvMvH/1DewwWP6gxgX+Faq5VrHVcP1qDXQje8ZM/ajRNdvqZv9begUqPQMckpGKmOWRXZV1/WFN4cbkJdTsf+t6iKTp+9lAyrhcOhPEI/C70SoN20/CFZMN8mDVJMxEeVgUmFD3nDpXLpUS0pzbQsbhiyQuwZaHs4uZMczkozMGgKWuy0IswLQhFl/2F25KHC/ogNrJ4d+W7GFnL+w4argNWcXevbHi+/jXiRcgMgGznAWRSc7Rb7+fIuwGxRLaZhRoH7pdaqtZfdK0VpU= sumner@scarif"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCt48Tnx9s1iNMOO9PzZVBUNwnc+p7kMZUhHIref+uZY9e7yjhTg+UvOPTYrhkVPmmVEzryzJurjRzU9KeNCL68jpfJAhSgphAtOoNUYbmE/yekJMOCMjPwDWuZ9A4uglfW1Jr4YeegI+N2/fmGNMwWo2a5fjtG+Tr981o12/9UhPE6cfOvVHESFbH14V9XnjoQjV91yZZJsr09aiJ6nWgxBMBn9XGwnTBEpEdJc/T1H0oNKuWumdlgtsWQ33lyFR5rZQ5Bhgy6xo3Oqz7UCkmtrEuNK6orPEyE8+KYokKBZmD/PfmmtpAvBRSQpuAhRAD5UKGLIxoclghq1wDnfpLrhjDBCsyTwPCbG8J7Iqd6/eTVXiedoitFYYkk4bMviBAE4IY4lH/l0TUdxZSa1mJN1z2ecVz/3GlKyHbHiHS9yJWh6C4I+hlryYnaiKanLPFgeX2yC+KJXnM8wqTCv1kiZuu8zXdyUguE22G87ZV8L6nZMorVN3Mgwor6BzYdyhs= colmena"
        ];
      };

      monitoring = { config, lib, pkgs, ... }: {
        deployment = {
          targetHost = "monitoring.nevarro.space";
          targetPort = 22;
          targetUser = "root";
          tags = [ "hetzner" "ashburn" ];

          keys = { };
        };

        networking.hostName = "monitoring";

        services.grafana = {
          enable = true;
          settings = {
            server.domain = "grafana.${config.networking.domain}";
          };
        };

        services.prometheus = {
          enable = true;
          scrapeConfigs = [
            {
              job_name = "monitoring";
              static_configs = [{
                targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
              }];
            }
            {
              job_name = "mineshspc";
              static_configs = [{
                targets = [ "10.0.1.1:${toString config.services.prometheus.exporters.node.port}" ];
              }];
            }
          ];
        };

        services.loki = {
          enable = true;
          configuration = {
            auth_enabled = false;
            server = {
              http_listen_port = 3100;
            };
            ingester = {
              lifecycler.ring = {
                kvstore.store = "inmemory";
                replication_factor = 1;
              };
              chunk_idle_period = "1h";
              chunk_target_size = 1048576;
              max_transfer_retries = 0;
            };
            schema_config = {
              configs = [
                {
                  from = "2022-03-03";
                  store = "boltdb-shipper";
                  object_store = "filesystem";
                  schema = "v11";
                  index = { prefix = "index_"; period = "24h"; };
                }
              ];
            };
            storage_config = {
              boltdb_shipper = {
                active_index_directory = "/var/lib/loki/boltdb-shipper-active";
                cache_location = "/var/lib/loki/boltdb-shipper-cache";
                cache_ttl = "24h";
                shared_store = "filesystem";
              };
              filesystem.directory = "/var/lib/loki/chunks";
            };
            limits_config = {
              reject_old_samples = true;
              reject_old_samples_max_age = "168h";
            };
            chunk_store_config.max_look_back_period = "0s";
            table_manager = {
              retention_deletes_enabled = false;
              retention_period = "0s";
            };
            compactor = {
              working_directory = "/var/lib/loki";
              shared_store = "filesystem";
              compactor_ring.kvstore.store = "inmemory";
            };
          };
        };

        services.nginx = {
          enable = true;
          enableReload = true;
          clientMaxBodySize = "250m";
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;

          appendConfig = ''
            worker_processes auto;
          '';
          eventsConfig = ''
            worker_connections 8192;
          '';

          virtualHosts.${config.services.grafana.settings.server.domain} = {
            enableACME = true;
            forceSSL = true;

            locations."/" = {
              proxyPass = with config.services.grafana.settings.server; "http://${http_addr}:${toString http_port}";
              proxyWebsockets = true;
              extraConfig = ''
                access_log /var/log/nginx/grafana.access.log;
              '';
            };
          };
        };

        # Open up the ports
        networking.firewall.allowedTCPPorts = [ 80 443 3100 ];
      };

      mineshspc = { config, lib, pkgs, ... }: {
        deployment = {
          targetHost = "mineshspc.com";
          targetPort = 22;
          targetUser = "root";
          tags = [ "hetzner" "ashburn" ];

          keys = {
            mineshspc_env.keyCommand = [ "cat" "../infrastructure-secrets/secrets/mineshspc_env" ];
            restic_password_file.keyCommand = [ "cat" "../infrastructure-secrets/secrets/restic_password_file" ];
            restic_environment_file.keyCommand = [ "cat" "../infrastructure-secrets/secrets/restic_environment_file" ];
          };
        };

        networking.hostName = "mineshspc";

        services.nginx = {
          enable = true;
          enableReload = true;
          clientMaxBodySize = "250m";
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;

          appendConfig = ''
            worker_processes auto;
          '';
          eventsConfig = ''
            worker_connections 8192;
          '';

          virtualHosts."mineshspc.com" = {
            enableACME = true;
            forceSSL = true;

            locations."/" = {
              proxyPass = "http://0.0.0.0:8090"; # without a trailing /
              extraConfig = ''
                access_log /var/log/nginx/mineshspc.access.log;
              '';
            };
          };
        };

        # Open up the ports
        networking.firewall.allowedTCPPorts = [ 80 443 ];

        virtualisation.oci-containers.containers = {
          "mineshspc.com" = {
            image = "ghcr.io/coloradoschoolofmines/mineshspc.com:d3fb9b2ea6eef8dd5bd037db61c9966d44ab4411";
            volumes = [ "/var/lib/mineshspc:/data" ];
            ports = [ "8090:8090" ];
            environmentFiles = [ "/run/keys/mineshspc_env" ];
            environment = {
              MINESHSPC_DOMAIN = "https://mineshspc.com";
              MINESHSPC_HOSTED_BY_HTML = ''
                Hosting provided by <a href="https://nevarro.space" target="_blank">Nevarro LLC</a>.
                Check the <a href="https://status.mineshspc.com/" target="_blank">site status</a>.
              '';
              MINESHSPC_REGISTRATION_ENABLED = "0";
            };
          };
        };
        systemd.services."${config.virtualisation.oci-containers.backend}-mineshspc.com" = {
          after = [ "mineshspc_env-key.service" ];
          partOf = [ "mineshspc_env-key.service" ];
        };

        # Make sure that the working directory is available
        system.activationScripts.makeMinesHSPCDir = lib.stringAfter [ "var" ] ''
          mkdir -p /var/lib/mineshspc
        '';

        systemd.services."restic-backup" =
          let
            resticCmd = "${pkgs.restic}/bin/restic --verbose=3";
            resticBackupScript = paths: exclude: pkgs.writeShellScriptBin "restic-backup" ''
              set -xe

              # Perfrom the backup
              ${resticCmd} backup \
                ${lib.concatStringsSep " " paths} \
                ${lib.concatMapStringsSep " " (e: "-e \"${e}\"") exclude}

              # Make sure that the backup has time to settle before running the check.
              sleep 10

              # Check the validity of the repository.
              ${resticCmd} check
            '';
            script = resticBackupScript [ "/var/lib/mineshspc" ] [ ];
          in
          {
            description = "Run Restic Backup";
            environment = {
              RESTIC_PASSWORD_FILE = "/run/keys/restic_password_file";
              RESTIC_REPOSITORY = "b2:nevarro-backups:mineshspc";
              RESTIC_CACHE_DIR = "/var/cache";
            };
            startAt = "0/2:0"; # Run backup every 2 hours
            serviceConfig = {
              ExecStart = "${script}/bin/restic-backup";
              EnvironmentFile = "/run/keys/restic_environment_file";
              PrivateTmp = true;
              ProtectSystem = true;
              ProtectHome = "read-only";
            };
            # Initialize the repository if it doesn't exist already.
            preStart = ''
              ${resticCmd} snapshots || ${resticCmd} init
            '';
          };
      };
    };
  };
}
