{ config, ... }:
let
  matrixDomain = "matrix.${config.networking.domain}";
  internalIPs = [
    "10.0.1.2" # monitoring
    "10.0.1.3" # matrix
    "10.0.1.4" # mineshspc
  ];
in {
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "monitoring";
  systemd.network.networks = {
    "10-wan" = {
      matchConfig.MACAddress = "96:00:02:1f:07:ec";
      address = [ "2a01:4ff:f0:9b5d::1/64" ];
    };
    "10-nevarronet".matchConfig.MACAddress = "86:00:00:43:8c:62";
  };

  services.goatcounter = {
    enable = true;
    extraArgs = [ "-websocket" ];
    proxy = true;
    port = 7128;
  };
  services.nginx = {
    enable = true;
    virtualHosts = {
      "stats.nevarro.space" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:7128";
          recommendedProxySettings = true;
          proxyWebsockets = true;
        };
      };
      "stats.sumnerevans.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:7128";
          recommendedProxySettings = true;
          proxyWebsockets = true;
        };
      };
    };
  };

  services.grafana.enable = true;
  services.loki.enable = true;

  services.prometheus = {
    enable = true;

    # Make sure that Prometheus is setup for Synapse.
    scrapeConfigs = (map (ip: {
      job_name = ip;
      static_configs = [{ targets = [ "${ip}:9002" ]; }];
    }) internalIPs) ++ [{
      job_name = "synapse";
      scrape_interval = "15s";
      metrics_path = "/_synapse/metrics";
      static_configs = [
        {
          targets = [ "10.0.1.3:9009" ];
          labels = {
            instance = matrixDomain;
            job = "master";
            index = "1";
          };
        }
        {
          # Federation sender 1
          targets = [ "10.0.1.3:9101" ];
          labels = {
            instance = matrixDomain;
            job = "federation_sender";
            index = "1";
          };
        }
        {
          # Federation sender 2
          targets = [ "10.0.1.3:9106" ];
          labels = {
            instance = matrixDomain;
            job = "federation_sender";
            index = "2";
          };
        }
        {
          # Federation reader 1
          targets = [ "10.0.1.3:9102" ];
          labels = {
            instance = matrixDomain;
            job = "federation_reader";
            index = "1";
          };
        }
        {
          # Event persister 1
          targets = [ "10.0.1.3:9103" ];
          labels = {
            instance = matrixDomain;
            job = "event_persister";
            index = "1";
          };
        }
        {
          # Event persister 2
          targets = [ "10.0.1.3:9107" ];
          labels = {
            instance = matrixDomain;
            job = "event_persister";
            index = "2";
          };
        }
        {
          # Synchotron 1
          targets = [ "10.0.1.3:9104" ];
          labels = {
            instance = matrixDomain;
            job = "synchotron";
            index = "1";
          };
        }
        {
          # Media repo 1
          targets = [ "10.0.1.3:9105" ];
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
    url =
      "https://heartbeat.uptimerobot.com/m798927859-250faf0ac3b6657ccc5f90b1923aa6afc3719748";
    disks = [{
      path = "/";
      threshold = 95;
      url =
        "https://heartbeat.uptimerobot.com/m798927865-2e9fa771d33b4450dca50d0a0d0ea33b1685d3d8";
    }];
  };
}
