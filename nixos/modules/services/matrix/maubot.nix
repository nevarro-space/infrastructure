{ config, lib, pkgs, ... }:
let
  port = 29316;
  dataDir = "/var/lib/maubot";
in {
  options = {
    services.maubot-docker.enable = lib.mkEnableOption "Maubot via Docker";
  };

  config = lib.mkIf config.services.maubot-docker.enable {
    virtualisation.oci-containers = {
      backend = "docker";
      containers.maubot = {
        volumes = [ "${dataDir}:/data:z" ];
        ports = [ "${toString port}:${toString port}" ];
        image =
          "dock.mau.dev/maubot/maubot:094e1eca35fd7d859bdf03db0555925986265996-amd64";
      };
    };

    systemd.services = {
      "maubot-mkcfg" = {
        description = "Generate Maubot configuration";
        wantedBy = [ "multi-user.target" ];
        after = [ "maubot_yaml-key.service" ];
        requires = [ "maubot_yaml-key.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${pkgs.coreutils}/bin/cp /run/keys/maubot_yaml ${dataDir}/config.yaml
          '';
          SupplementaryGroups = [ "keys" ];
        };
      };
      ${config.virtualisation.oci-containers.containers.maubot.serviceName} = {
        after = [ "maubot-mkcfg.service" ];
        requires = [ "maubot-mkcfg.service" ];
        partOf = [ "maubot-mkcfg.service" ];
      };
    };

    services.nginx.virtualHosts."matrix.nevarro.space".locations = {
      "/_matrix/maubot/" = {
        proxyPass = "http://localhost:${toString port}";
        proxyWebsockets = true;
      };
    };
  };
}
