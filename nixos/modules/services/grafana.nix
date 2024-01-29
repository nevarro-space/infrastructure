{ config, lib, ... }:
with lib;
let
  serverName = "grafana.${config.networking.domain}";
  cfg = config.services.grafana;
in mkIf cfg.enable {
  services.grafana.settings = { server.domain = serverName; };

  services.nginx = {
    enable = true;

    virtualHosts.${cfg.settings.server.domain} = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = with cfg.settings.server;
          "http://${http_addr}:${toString http_port}";
        proxyWebsockets = true;
        extraConfig = ''
          access_log /var/log/nginx/grafana.access.log;
        '';
      };
    };
  };
}
