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
        (self: super: {
          # Custom package that tracks with the latest release of Synapse.
          matrix-synapse-unwrapped = super.matrix-synapse-unwrapped.overridePythonAttrs (old: rec {
            pname = "matrix-synapse";
            version = "1.91.2";
            format = "pyproject";

            src = super.fetchFromGitHub {
              owner = "matrix-org";
              repo = "synapse";
              rev = "v${version}";
              hash = "sha256-U9SyDmO34s9PjLPnT1QYemGeCmKdXRaQvEC8KKcFXOI=";
            };

            cargoDeps = super.rustPackages.rustPlatform.fetchCargoTarball {
              inherit src;
              name = "${pname}-${version}";
              hash = "sha256-q3uoT2O/oTVSg6olZohU8tiWahijyva+1tm4e1GWGj4=";
            };

            doCheck = false;
          });
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
