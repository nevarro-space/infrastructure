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
}
