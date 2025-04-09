{ nixpkgs, terraform-outputs, mineshspc, ... }:
let system = "x86_64-linux";
in {
  meta = {
    nixpkgs = import nixpkgs {
      inherit system;
      config.permittedInsecurePackages = [ "olm-3.2.16" ];
      overlays = [
        (self: super: { inherit (mineshspc.packages.${system}) mineshspc; })
        (self: super: {
          # Custom package that tracks with the latest release of Synapse.
          matrix-synapse-unwrapped =
            super.matrix-synapse-unwrapped.overridePythonAttrs (old: rec {
              pname = "matrix-synapse";
              version = "1.128.0";

              src = super.fetchFromGitHub {
                owner = "element-hq";
                repo = "synapse";
                rev = "v${version}";
                hash = "sha256-QgVx/9mZ3Do+42YwO8OtI2dcuckMX/xIaiBUi4HrK4Q=";
              };

              cargoDeps = super.rustPlatform.fetchCargoVendor {
                inherit src;
                name = "${pname}-${version}";
                hash = "sha256-PdAyEGLYmMLgcPQjzjuwvQo55olKgr079gsgQnUoKTM=";
              };

              doInstallCheck = false;
              doCheck = false;
            });
        })
        (self: super: {
          meowlnir = super.meowlnir.overrideAttrs (old: {
            pname = "meowlnir";
            version = "0.4.0rc2";

            src = super.fetchFromGitHub {
              owner = "maunium";
              repo = "meowlnir";
              rev = "a5fd8ffe78577371b95274366ad44fc6f156f92e";
              hash = "sha256-MUycnf1TSLCTk7A72QbCS0ChSVwZP1jH1Ry5Q0L+L2I=";
            };

            vendorHash = "sha256-+P7tlpGTo9N+uSn22uAlzyB36hu3re+KfOe3a/uzLZE=";

            doInstallCheck = false;
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
