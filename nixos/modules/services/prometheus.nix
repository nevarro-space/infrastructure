let promPort = 9002;
in {
  config = {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      port = promPort;
    };

    networking.firewall.allowedTCPPorts = [ promPort ];
  };
}
