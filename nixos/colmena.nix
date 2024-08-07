{ nixpkgs, terraform-outputs, mineshspc, meetbot, ... }:
let system = "x86_64-linux";
in {
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
          matrix-synapse-unwrapped =
            super.matrix-synapse-unwrapped.overridePythonAttrs (old: rec {
              pname = "matrix-synapse";
              version = "1.112.0";
              format = "pyproject";

              src = super.fetchFromGitHub {
                owner = "element-hq";
                repo = "synapse";
                rev = "v${version}";
                hash = "sha256-8iXw9C91kPWDlzo/3AA/iVCQqq47eGSORMTzEQTTS+8=";
              };

              cargoDeps = super.rustPackages.rustPlatform.fetchCargoTarball {
                inherit src;
                name = "${pname}-${version}";
                hash = "sha256-hx/IMOxk4vUHXMMIcnxnC3RJcIvJL+IooZnf+m+VKSs=";
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
