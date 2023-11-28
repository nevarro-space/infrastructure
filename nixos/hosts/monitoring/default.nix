{ config, lib, terraform-outputs, ... }:
with lib;
let matrixDomain = "matrix.${config.networking.domain}";
in {
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "monitoring";
  systemd.network.networks = {
    "10-wan".matchConfig.MACAddress = "96:00:02:1f:07:ec";
    "10-nevarronet".matchConfig.MACAddress = "86:00:00:43:8c:62";
  };

  services.grafana.enable = true;
  services.loki.enable = true;

  services.prometheus = {
    enable = true;

    # Make sure that Prometheus is setup for Synapse.
    scrapeConfigs = (mapAttrsToList
      (k: v: {
        job_name = elemAt (splitString "_" k) 0;
        static_configs = [{ targets = [ "${toString v.value}:9002" ]; }];
      })
      (filterAttrs (k: v: lib.hasInfix "_server_internal_ip" k)
        terraform-outputs)) ++ [{
      job_name = "synapse";
      scrape_interval = "15s";
      metrics_path = "/_synapse/metrics";
      static_configs = [
        {
          targets =
            [ "${terraform-outputs.matrix_server_internal_ip.value}:9009" ];
          labels = {
            instance = matrixDomain;
            job = "master";
            index = "1";
          };
        }
        {
          # Federation sender 1
          targets =
            [ "${terraform-outputs.matrix_server_internal_ip.value}:9101" ];
          labels = {
            instance = matrixDomain;
            job = "federation_sender";
            index = "1";
          };
        }
        {
          # Federation sender 2
          targets =
            [ "${terraform-outputs.matrix_server_internal_ip.value}:9106" ];
          labels = {
            instance = matrixDomain;
            job = "federation_sender";
            index = "2";
          };
        }
        {
          # Federation reader 1
          targets =
            [ "${terraform-outputs.matrix_server_internal_ip.value}:9102" ];
          labels = {
            instance = matrixDomain;
            job = "federation_reader";
            index = "1";
          };
        }
        {
          # Event persister 1
          targets =
            [ "${terraform-outputs.matrix_server_internal_ip.value}:9103" ];
          labels = {
            instance = matrixDomain;
            job = "event_persister";
            index = "1";
          };
        }
        {
          # Event persister 2
          targets =
            [ "${terraform-outputs.matrix_server_internal_ip.value}:9107" ];
          labels = {
            instance = matrixDomain;
            job = "event_persister";
            index = "2";
          };
        }
        {
          # Synchotron 1
          targets =
            [ "${terraform-outputs.matrix_server_internal_ip.value}:9104" ];
          labels = {
            instance = matrixDomain;
            job = "synchotron";
            index = "1";
          };
        }
        {
          # Media repo 1
          targets =
            [ "${terraform-outputs.matrix_server_internal_ip.value}:9105" ];
          labels = {
            instance = matrixDomain;
            job = "media_repo";
            index = "1";
          };
        }
      ];
    }];
  };

  services.healthcheck = {
    enable = true;
    checkId = "30252d36-5283-4fb1-89c4-ad392f817e81";
    disks = [{
      path = "/";
      threshold = 95;
      checkId = "eb00bb37-af3c-4f4e-8eab-e14cdc9ebe97";
    }];
  };
}
