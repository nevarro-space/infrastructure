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
    };
  };

  iniFormat = pkgs.formats.ini { };
  pc2ConfigFile = iniFormat.generate "pc2v9.ini" pc2Config;

  wtiAppConfig = {
    production = true;
    baseUrl = "https://${cfg.wti.virtualHost}/api";
    websocketUrl = "wss://${cfg.wti.virtualHost}/websocket/WTISocket";
  };

  jsonFormat = pkgs.formats.json { };
  wtiAppConfigFile = jsonFormat.generate "appconfig.json" wtiAppConfig;
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
        cp --no-preserve=mode,ownership -r ${pc2}/wti/WebContent ${cfg.wti.dataDir}
        cp ${pc2ConfigFile} ${cfg.wti.dataDir}/pc2v9.ini
        cp ${wtiAppConfigFile} ${cfg.wti.dataDir}/WebContent/WTI-UI/assets/appconfig.json
      '';
      serviceConfig = {
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" "CAP_SYS_RESOURCE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" "CAP_SYS_RESOURCE" ];
        ExecStart = "${pc2}/wti/bin/pc2wti";
        WorkingDirectory = cfg.wti.dataDir;
        Restart = "always";
        User = "pc2wti";
        Group = "pc2";
      };
    };
    networking.firewall.allowedTCPPorts = [ cfg.wti.port ];

    users.users.pc2wti = {
      description = "PC^2 WTI User";
      group = "pc2";
      name = "pc2wti";
      home = cfg.wti.dataDir;
      createHome = true;
      isSystemUser = true;
    };
  };
}
