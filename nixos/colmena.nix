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

  mineshspc = { config, lib, pkgs, ... }: {
    deployment = {
      targetHost = "mineshspc.com";
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/mineshspc ];
  };

  pc2test = { config, lib, pkgs, ... }: {
    deployment = {
      targetHost = "pc2test.mineshspc.com";
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/pc2test ];
  };
}
