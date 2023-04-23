{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.pc2;
  pc2 = pkgs.callPackage ../../../pkgs/pc2.nix { };

  pc2Config = {
    client = {
      server = "localhost:50002";
    };
    server = {
      wtiport = cfg.wti.port;
      wtiwsName = "/websocket";
      wtiscoreboardaccount = "scoreboard2";
      wtiscoreboardpassword = "scoreboard2";
      wtiOverridePublicIP = cfg.wti.externalIP;
    };
  };

  iniFormat = pkgs.formats.ini { };
  pc2ConfigFile = iniFormat.generate "pc2v9.ini" pc2Config;
in
{
  options.services.pc2.wti = {
    enable = mkEnableOption "PC^2 CCS Web Team Interface";
    virtualHost = mkOption {
      type = types.str;
      description = "The URL of the WTI server.";
    };
    port = mkOption {
      type = types.int;
      default = 8080;
      description = "The port to run the WTI server on.";
    };
    externalIP = mkOption {
      type = types.str;
      description = "The external IP of the WTI server.";
    };
    dataDir = mkOption {
      type = types.path;
      description = "The root directory for PC^2 server data.";
      default = "/var/lib/pc2wti";
    };
  };

  config = mkIf cfg.wti.enable {
    systemd.services.pc2wti = {
      description = "PC^2 Web Team Interface";
      after = [ "network.target" "pc2server.service" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        # Setup config
        rm -rf ${cfg.wti.dataDir}/*
        ln -s ${pc2ConfigFile} ${cfg.wti.dataDir}/pc2v9.ini
        ln -s ${pc2}/wti/WebContent ${cfg.wti.dataDir}
      '';
      serviceConfig = {
        ExecStart = "${pc2}/wti/bin/pc2wti";
        WorkingDirectory = cfg.wti.dataDir;
        Restart = "always";
        User = "pc2wti";
        Group = "pc2";
      };
    };

    users.users.pc2wti = {
      description = "PC^2 WTI User";
      group = "pc2";
      name = "pc2wti";
      home = cfg.wti.dataDir;
      createHome = true;
      isSystemUser = true;
    };

    services.nginx = {
      enable = true;

      virtualHosts.${cfg.wti.virtualHost} = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://localhost:${toString cfg.wti.port}";
          proxyWebsockets = true;
          extraConfig = ''
            access_log /var/log/nginx/pc2wti.access.log;
          '';
        };
      };
    };
  };
}
