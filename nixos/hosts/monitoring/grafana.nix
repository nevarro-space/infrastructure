{ config, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      server.domain = "grafana.${config.networking.domain}";

      security.secret_key = "$__file{/run/keys/grafana_secret_key}";
    };
  };

  systemd.services.grafana.serviceConfig.SupplementaryGroups = [ "keys" ];

  services.nginx = {
    enable = true;

    virtualHosts.${config.services.grafana.settings.server.domain} = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass =
          with config.services.grafana.settings.server;
          "http://${http_addr}:${toString http_port}";
        proxyWebsockets = true;
        extraConfig = ''
          access_log /var/log/nginx/grafana.access.log;
        '';
      };
    };
  };
}
