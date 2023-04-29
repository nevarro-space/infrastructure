{ nixpkgs-unstable, ... }: {
  meta = {
    nixpkgs = import nixpkgs-unstable { system = "x86_64-linux"; };
    description = "Nevarro Infrastructure";
  };

  defaults = { config, ... }: {
    deployment.replaceUnknownProfiles = true;

    imports = [
      ./modules
    ];

    system.stateVersion = "23.05";

    networking.domain = "nevarro.space";
    networking.interfaces.eth0.useDHCP = true;

    swapDevices = [
      { device = "/var/swapfile"; size = 4096; }
    ];
  };

  monitoring = {
    deployment = {
      targetHost = "monitoring.nevarro.space";
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/monitoring ];
  };

  matrix = {
    deployment = {
      targetHost = "5.161.216.225";
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/matrix ];
  };

  mineshspc = { config, lib, pkgs, ... }: {
    deployment = {
      targetHost = "mineshspc.com";
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/mineshspc ];
  };
}
