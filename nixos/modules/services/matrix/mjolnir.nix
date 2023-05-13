{ config, lib, pkgs, ... }: with lib; let
  mjolnirCfg = config.services.mjolnir;
in
{
  services.mjolnir = {
    pantalaimon = {
      enable = true;
      options = {
        listenAddress = "127.0.0.1";
        listenPort = 8100;
      };
    };

    settings = {
      protectAllJoinedRooms = true;
    };
  };
  systemd.services.mjolnir.serviceConfig.SupplementaryGroups = [ "keys" ];
  services.pantalaimon-headless.instances = mkIf mjolnirCfg.enable {
    mjolnir = {
      listenAddress = "127.0.0.1";
      listenPort = 8100;
    };
  };
}
