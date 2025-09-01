{ nixpkgs, mineshspc, ... }:
let system = "x86_64-linux";
in {
  meta = {
    description = "Nevarro Infrastructure";

    nixpkgs = import nixpkgs {
      inherit system;
      config.permittedInsecurePackages = [ "olm-3.2.16" ];
      overlays = [
        (self: super: { inherit (mineshspc.packages.${system}) mineshspc; })
        # (self: super: {
        #   # Custom package that tracks with the latest release of Synapse.
        #   matrix-synapse-unwrapped =
        #     super.matrix-synapse-unwrapped.overridePythonAttrs (old: rec {
        #       pname = "matrix-synapse";
        #       version = "1.137.0";
        #
        #       src = super.fetchFromGitHub {
        #         owner = "element-hq";
        #         repo = "synapse";
        #         rev = "v${version}";
        #         hash = "sha256-jnbW1p5JK00Of6XqoDfWs/4SqIztafjkvXUDWhMTm30=";
        #       };
        #
        #       cargoDeps = super.rustPlatform.fetchCargoVendor {
        #         inherit src;
        #         name = "${pname}-${version}";
        #         hash = "sha256-qpgDErV1VVzaUHHQX4ReXCPihdrSKI/4HtbDeQIblR8=";
        #       };
        #
        #       doInstallCheck = false;
        #       doCheck = false;
        #     });
        # })
      ];
    };
  };

  defaults = { config, ... }: {
    imports = [ ./modules ];

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
      targetHost = "monitoring.nevarro.space";
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/monitoring ];
  };

  matrix = {
    deployment = {
      targetHost = "matrix.nevarro.space";
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/matrix ];
  };

  mineshspc = {
    deployment = {
      targetHost = "mineshspc.com";
      tags = [ "hetzner" "ashburn" ];
    };

    imports = [ ./hosts/mineshspc ];
  };
}
