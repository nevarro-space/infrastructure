{ lib, ... }:
{
  services.goatcounter = {
    enable = true;
    extraArgs = [
      "-websocket"
      "-automigrate"
    ];
    proxy = true;
    port = 7128;
  };

  services.nginx = {
    enable = true;
    virtualHosts =
      let
        domains = [
          "stats.nevarro.space"
          "stats.scopedcommits.com"
          "stats.sumnerevans.com"
        ];
      in
      lib.genAttrs domains (_: {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:7128";
          recommendedProxySettings = true;
          proxyWebsockets = true;
        };
      });
  };
}
