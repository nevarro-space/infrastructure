{ nixpkgs, terraform-outputs, mineshspc, meetbot, ... }:
let
  system = "x86_64-linux";
in
{
  meta = {
    nixpkgs = import nixpkgs {
      inherit system;
      overlays = [
        (self: super: {
          inherit (mineshspc.packages.${system}) mineshspc;
          inherit (meetbot.packages.${system}) meetbot;
        })
      ];
    };
    description = "Nevarro Infrastructure";
  };

  defaults = { config, ... }: {
    imports = [ ./modules ];

    _module.args = {
      inherit terraform-outputs;
    };

    deployment.replaceUnknownProfiles = true;

    system.stateVersion = "23.05";

    networking.domain = "nevarro.space";
    networking.interfaces.eth0.useDHCP = true;

    swapDevices = [
      { device = "/var/swapfile"; size = 4096; }
    ];

    services.logrotate.enable = true;
  };

  monitoring = {
    deployment = {
      targetHost = terraform-outputs.monitoring_server_ipv4.value;
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/monitoring ];
  };

  matrix = {
    deployment = {
      targetHost = terraform-outputs.matrix_server_ipv4.value;
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/matrix ];
  };

  mineshspc = {
    deployment = {
      targetHost = terraform-outputs.mineshspc_server_ipv4.value;
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/mineshspc ];
  };
}
