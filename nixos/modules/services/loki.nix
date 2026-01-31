{ config, lib, ... }:
let
  lokiCfg = config.services.loki;
in
lib.mkIf lokiCfg.enable {
  services.loki.configuration = {
    auth_enabled = false;
    server.http_listen_port = 3100;

    common = {
      ring = {
        instance_addr = "0.0.0.0";
        kvstore.store = "inmemory";
      };
      replication_factor = 1;
      path_prefix = "/tmp/loki";
    };

    schema_config = {
      configs = [
        {
          from = "2024-05-07";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
    };

    storage_config.filesystem.directory = "/var/lib/loki/chunks";

    ingester = {
      lifecycler.ring = {
        kvstore.store = "inmemory";
        replication_factor = 1;
      };
      chunk_idle_period = "1h";
      chunk_target_size = 1048576;
    };

    limits_config = {
      retention_period = "744h";
      reject_old_samples = true;
      reject_old_samples_max_age = "168h";
    };
    table_manager = {
      retention_deletes_enabled = false;
      retention_period = "0s";
    };
    compactor = {
      working_directory = "/var/lib/loki";
      compaction_interval = "10m";
      retention_enabled = true;
      retention_delete_delay = "2h";
      retention_delete_worker_count = 20;
      delete_request_store = "filesystem";
    };
  };

  # Open up the ports
  networking.firewall.allowedTCPPorts = [ 3100 ];
}
