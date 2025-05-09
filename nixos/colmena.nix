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
        (self: super: {
          # Custom package that tracks with the latest release of Synapse.
          matrix-synapse-unwrapped =
            super.matrix-synapse-unwrapped.overridePythonAttrs (old: rec {
              pname = "matrix-synapse";
              version = "1.129.0";

              src = super.fetchFromGitHub {
                owner = "element-hq";
                repo = "synapse";
                rev = "v${version}";
                hash = "sha256-JDaTFbRb2eNtzxZBLn8wOBEN5uJcInNrhFnGFZjI8is=";
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
          mautrix-discord = super.mautrix-discord.overrideAttrs (old: rec {
            pname = "mautrix-discord";
            version = "0.7.3";

            src = super.fetchFromGitHub {
              owner = "mautrix";
              repo = "discord";
              rev = "v${version}";
              hash = "sha256-q6FpeGWoeIVVeomKMHpXUntMWsMJMV73FDiBfbMQ6Oc=";
            };

            vendorHash = "sha256-6R5ryzjAAAI3YtTMlHjrLOXkid2kCe8+ZICnNUjtxaQ=";

            doInstallCheck = false;
          });
        })
        (self: super: {
          meowlnir = super.meowlnir.overrideAttrs (old: {
            pname = "meowlnir";
            version = "0.4.0";

            src = super.fetchFromGitHub {
              owner = "maunium";
              repo = "meowlnir";
              rev = "v0.4.0";
              hash = "sha256-wPPL/4ky7AAR6gL0EIdfpkpdOGPIAZ7pm8NEZDT6hv0=";
            };

            vendorHash = "sha256-s6GlTES+h+0HpthTXN7V/ddPtIeEmtJ83xn7QVQknLA=";

            doInstallCheck = false;
          });
        })
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
