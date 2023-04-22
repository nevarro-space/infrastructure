{ config, ... }: {
  networking.hostName = "monitoring";

  services.grafana = {
    enable = true;
    settings = {
      server.domain = "grafana.${config.networking.domain}";
    };
  };

  services.prometheus =
    let
      portStr = toString config.services.prometheus.exporters.node.port;
    in
    {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "monitoring";
          static_configs = [{
            targets = [ "127.0.0.1:${portStr}" ];
          }];
        }
        {
          job_name = "mineshspc";
          static_configs = [{
            targets = [ "10.0.1.1:${portStr}" ];
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
  networking.firewall.allowedTCPPorts = [ 3100 ];
}
