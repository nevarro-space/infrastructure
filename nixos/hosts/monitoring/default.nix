{ config, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "monitoring";

  services.grafana = {
    enable = true;
    settings = {
      server.domain = "grafana.${config.networking.domain}";
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
        {
          job_name = "matrix";
          static_configs = [{
            targets = [ "10.0.1.3:${portStr}" ];
          }];
        }
      ];
    };

  services.loki.enable = true;
}
