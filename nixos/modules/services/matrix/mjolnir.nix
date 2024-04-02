{ config, lib, ... }:
with lib;
let mjolnirCfg = config.services.mjolnir;
in mkIf mjolnirCfg.enable {
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
      verboseLogging = false;
    };
  };
  systemd.services.mjolnir = {
    requires = [ "matrix-synapse.target" "marshal_password-key.service" ];
    serviceConfig.SupplementaryGroups = [ "keys" ];
  };
  services.pantalaimon-headless.instances.mjolnir = {
    listenAddress = "127.0.0.1";
    listenPort = 8100;
  };
}
