{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.pc2;
  pc2 = pkgs.callPackage ../../../pkgs/pc2.nix { };

  pc2Config = { };
  iniFormat = pkgs.formats.ini { };
  configFile = iniFormat.generate "pc2v9.ini" pc2Config;
in
{
  options.services.pc2.server = {
    enable = mkEnableOption "PC^2 CCS Server";
    port = mkOption {
      type = types.int;
      default = 50002;
      description = "The port to expose the PC^2 server on.";
    };
    dataDir = mkOption {
      type = types.path;
      description = "The root directory for PC^2 server data.";
      default = "/var/lib/pc2server";
    };
  };

  config = mkIf cfg.server.enable {
    systemd.services.pc2server = {
      description = "PC^2 Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${pc2}/bin/pc2admin \
            --nogui \
            --login site1 \
            --password site1 \
            --contestpassword ohea \
            --server \
            --port ${toString cfg.server.port} \
            --ini ${configFile} \
            --load ${cfg.contestPkg}
        '';
        WorkingDirectory = cfg.server.dataDir;
        Restart = "always";
        User = "pc2server";
        Group = "pc2";
      };
    };

    users.users.pc2server = {
      description = "PC^2 Server User";
      group = "pc2";
      name = "pc2server";
      home = cfg.server.dataDir;
      createHome = true;
      isSystemUser = true;
    };
  };
}
