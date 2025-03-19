{ config, lib, pkgs, ... }:
lib.mkIf config.services.maubot.enable {
  services.maubot = {
    pythonPackages = with pkgs.python3Packages; [ aiohttp ];
    extraConfigFile = "/run/keys/maubot_yaml";
  };

  systemd.services.maubot = {
    after = [ "maubot_yaml-key.service" ];
    serviceConfig.SupplementaryGroups = [ "keys" ];
  };

  services.nginx.virtualHosts."matrix.nevarro.space".locations."/_matrix/maubot/" =
    let port = config.services.maubot.settings.server.port;
    in {
      proxyPass = "http://localhost:${toString port}";
      proxyWebsockets = true;
    };
}
