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
              version = "1.99.0";
              format = "pyproject";

              src = super.fetchFromGitHub {
                owner = "matrix-org";
                repo = "synapse";
                rev = "v${version}";
                hash = "sha256-NS0in7zUkIS+fI5gQEua9y1UXspEHWNCntyZHZCtfPg=";
              };

              cargoDeps = super.rustPackages.rustPlatform.fetchCargoTarball {
                inherit src;
                name = "${pname}-${version}";
                hash = "sha256-FQhHpbp8Rkkqp6Ngly/HP8iWGlWh5CDaztgAwKB/afI=";
              };

              postPatch = ''
                # Remove setuptools_rust from runtime dependencies
                # https://github.com/matrix-org/synapse/blob/v1.69.0/pyproject.toml#L177-L185
                sed -i '/^setuptools_rust =/d' pyproject.toml

                # Remove version pin on build dependencies. Upstream does this on purpose to
                # be extra defensive, but we don't want to deal with updating this
                sed -i 's/"poetry-core>=\([0-9.]*\),<=[0-9.]*"/"poetry-core>=\1"/' pyproject.toml
                sed -i 's/"setuptools_rust>=\([0-9.]*\),<=[0-9.]*"/"setuptools_rust>=\1"/' pyproject.toml

                # Don't force pillow to be 10.0.1 because we already have patched it, and
                # we don't use the pillow wheels.
                sed -i 's/Pillow = ".*"/Pillow = ">=5.4.0"/' pyproject.toml
              '';

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
