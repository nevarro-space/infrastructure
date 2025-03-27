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
              version = "1.127.1";

              src = super.fetchFromGitHub {
                owner = "element-hq";
                repo = "synapse";
                rev = "v${version}";
                hash = "sha256-DNUKbb+d3BBp8guas6apQ4yFeXCc0Ilijtbt1hZkap4=";
              };

              cargoDeps = super.rustPlatform.fetchCargoVendor {
                inherit src;
                name = "${pname}-${version}";
                hash = "sha256-wI3vOfR5UpVFls2wPfgeIEj2+bmWdL3pDSsKfT+ysw8=";
              };

              doInstallCheck = false;
              doCheck = false;
            });
        })
        (self: super: {
          meowlnir = super.meowlnir.overrideAttrs (old: {
            pname = "meowlnir";
            version = "0.4.0rc1";

            src = super.fetchFromGitHub {
              owner = "maunium";
              repo = "meowlnir";
              rev = "2dae5bc4ded6d5da7d5118193922a387b62b53c5";
              hash = "sha256-HqZHLBPTXEE0DLjglumIPxAquP9TZ1EjK493ATupcVo=";
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
