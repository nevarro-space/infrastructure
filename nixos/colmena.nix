{ nixpkgs, terraform-outputs, mineshspc, meetbot, ... }:
let system = "x86_64-linux";
in {
  meta = {
    nixpkgs = import nixpkgs {
      inherit system;
      config.permittedInsecurePackages = [ "olm-3.2.16" ];
      overlays = [
        (self: super: {
          inherit (mineshspc.packages.${system}) mineshspc;
          inherit (meetbot.packages.${system}) meetbot;
        })
        (self: super: {
          # Custom package that tracks with the latest release of Synapse.
          matrix-synapse-unwrapped =
            super.matrix-synapse-unwrapped.overridePythonAttrs (old: rec {
              pname = "matrix-synapse";
              version = "1.120.0";

              src = super.fetchFromGitHub {
                owner = "element-hq";
                repo = "synapse";
                rev = "v${version}";
                hash = "sha256-3gPeit2r3q1WF72WUINS7gD8X9/DGQBmZYlUnaU7mvc=";
              };

              cargoDeps = super.rustPackages.rustPlatform.fetchCargoTarball {
                inherit src;
                name = "${pname}-${version}";
                hash = "sha256-ceIRDYHKpkw/H+ts5dXb5s4Eb8btbt/yHqOYqepWG/s=";
              };

              doInstallCheck = false;
              doCheck = false;
            });
        })
      ];
    };
    description = "Nevarro Infrastructure";
  };

  defaults = { config, ... }: {
    imports = [ ./modules ];

    _module.args = { inherit terraform-outputs; };

    deployment.replaceUnknownProfiles = true;

    system.stateVersion = "23.05";

    swapDevices = [{
      device = "/var/swapfile";
      size = 4096;
    }];

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
