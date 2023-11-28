{ config, lib, ... }:
let nginxCfg = config.services.nginx;
in lib.mkIf nginxCfg.enable {
  services.nginx = {
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
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
