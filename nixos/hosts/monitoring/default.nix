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

  services.loki.enable = true;
}
