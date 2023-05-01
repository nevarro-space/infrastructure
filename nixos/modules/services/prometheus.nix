{ config, lib, ... }: with lib; let
  cfg = config.services.prometheus;
  promPort = 9002;
in
{
  options = {
    services.prometheus.scrapeIPs = mkOption {
      type = with types; listOf (submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "The server's name.";
          };
          ip = mkOption {
            type = types.str;
            description = "The IP address to scrape.";
          };
        };
      });
      default = [ ];
    };
  };

  config = {
    services.prometheus = mkMerge [
      {
        exporters = {
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
            port = promPort;
          };
        };
      }
      (mkIf (cfg.scrapeIPs != [ ]) {
        enable = true;
        scrapeConfigs = map
          ({ name, ip }: {
            job_name = name;
            static_configs = [{
              targets = [ "${toString ip}:${toString promPort}" ];
            }];
          })
          cfg.scrapeIPs;
      })
    ];

    networking.firewall.allowedTCPPorts = [ promPort ];
  };
}
