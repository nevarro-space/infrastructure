{ config, lib, ... }:
let lokiCfg = config.services.loki;
in lib.mkIf lokiCfg.enable {
  services.loki.configuration = {
    auth_enabled = false;
    server = { http_listen_port = 3100; };
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
      configs = [{
        from = "2022-03-03";
        store = "boltdb-shipper";
        object_store = "filesystem";
        schema = "v11";
        index = {
          prefix = "index_";
          period = "24h";
        };
      }];
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
      retention_period = "744h";
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
      compaction_interval = "10m";
      retention_enabled = true;
      retention_delete_delay = "2h";
      retention_delete_worker_count = 20;
    };
  };

  # Open up the ports
  networking.firewall.allowedTCPPorts = [ 3100 ];
}
