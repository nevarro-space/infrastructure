{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }: {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ ];
        };
        description = "Nevarro Infrastructure";
      };

      mineshspc = { lib, pkgs, ... }: {
        deployment = {
          targetHost = "5.161.87.234";
          targetPort = 22;
          targetUser = "root";
          tags = [ "hetzner" "ashburn" ];
        };

        boot = {
          loader.grub.device = "/dev/sda";
          initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
          initrd.kernelModules = [ "nvme" ];
          cleanTmpDir = true;
          loader.timeout = 10;

          # Enable LISH
          kernelParams = [ "console=ttyS0,19200n8" ];
          loader.grub.extraConfig = ''
            serial --speed=19200 --unit=0 --word=8 --party=no --stop=1;
            terminal_input serial;
            terminal_output serial;
          '';
        };

        security.acme = {
          defaults.email = "admin@nevarro.space";
          acceptTerms = true;
        };

        services.nginx = {
          enable = true;
          enableReload = true;
          clientMaxBodySize = "250m";
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;

          appendConfig = ''
            worker_processes auto;
          '';
          eventsConfig = ''
            worker_connections 8192;
          '';

          virtualHosts."mineshspc.com" = {
            enableACME = true;
            forceSSL = true;

            locations."/" = {
              proxyPass = "http://0.0.0.0:8090"; # without a trailing /
              extraConfig = ''
                access_log /var/log/nginx/mineshspc.access.log;
              '';
            };
          };
        };
        # Open up the ports
        networking.firewall.allowedTCPPorts = [ 80 443 ];

        virtualisation.oci-containers.containers = {
          "mineshspc.com" = {
            image = "ghcr.io/coloradoschoolofmines/mineshspc.com:d61d4f7a2816191011e0c9e65e1856441da12876";
            volumes = [ "/var/lib/mineshspc:/data" ];
            ports = [ "8090:8090" ];
          };
        };

        system.activationScripts.makeMinesHSPCDir = lib.stringAfter [ "var" ] ''
          mkdir -p /var/lib/mineshspc
        '';

        fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };

        time.timeZone = "America/Denver";

        nix.gc.automatic = true;

        services.openssh.enable = true;
        services.openssh.permitRootLogin = "prohibit-password";

        networking.hostName = "mineshspc";
        networking.domain = "nevarro.space";
        networking.interfaces.eth0.useDHCP = true;

        swapDevices = [
          { device = "/var/swapfile"; size = 4096; }
        ];

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3oHcGiwPtWbee1x+6rKdovw4/CNIyE6MbBqC+irqZnyBLchboLKF+n9Vw9XRZxBPHppcb57oUTjh4gFA8N2vKqjVIacMNHSGFhRXBfUYtaTnmhzNj8sFWPwWpYAneTEe0hFdDKhL63nHZsi3XySh7R+BEIFZrDeyvKH86/GRpQwepVpQV3giqtqDA4GVgla/Zcea5ES1uxEolgDQKszXv8Z8iRUnrohrSAgsanjw6B+41X4qrwVnsStYhVN42tT8I7BM6kko9bdsLf4bg/WqdYDwPA4cbg1RkppqI0k7eBXPNfyaUKquiWz6tmrX5IMeIejjV+2BHgu0Q0iweMtPy41DGX6MaaKawWx5hoLds8fszVK02GUoCee26B8oEX+3TGKF9gj62gDcBOEmjLaGjxFrnk/DEkm3zSahwaIjxsbLK0/tFLh5B9Bha5mNF7tU88JwwJl+Zh3R7vGzHTqfZ7XVvSVSfpOPpVm0q3RSHMvVPSulOI+pTbA6GAQn0dT8= sumner@tatooine"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDasJXb4uvxPh0Z1NLa22dTx42VdWD+utRMbK0WeXS6XakIipx1YPb4yqbtUMJkoTLuFW/BUAEXSiks+ARD3Lc4K/iJeHHXbYvgklvr5dAPV6P2KtiVRZ+ipSLv1TF+al6hVUAnp4PPUQTv+3ZRA64QFrCAt26A7OnxKlowyW2KZVSqAcWPdQEbCdwILRCRIWTpbSj1rDeEsnvmu1G+Id5v7+uybQ+twBHbGpfYH7yWYLEhDtRyYu5SgnBcEh0bqszEgt+iLH/XzTQJILKdDaf4x8j/FJ9Px7+VQVfc+yADZ882ZsFzaxlmn7ndstAssmSSsHfRmNye0exIJqGXdxUfpF3w4h5qnR/0AJM7ljtXuDNOlOxflX0WvZinhhOJ/gF3No8sCXG/OcqlMNyrWd+vpJH4f9Xa0PTOn3Qpltq3YxWOZrWopUIDZw5jSsgLpLfC2NtGE/p5nEFnJCmMqrXPDY7dYS+65qYYjWXCzY3d9i3offwIQtV780Gu1VvT/zE= sumner@coruscant"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvBSffkOjq5nzFczPgaC41D5/6w1g1bK94YAAY4mBMVF8wh3aQF62X7FfV4cHM6wgUe2IOWinPZ/imL9+Nu9TsQbGc+mbfLltmZiGiHLqQBJOjMwwodxdkljhPmwUvALemyNiHkJ2yAvnMqSBteJuAv8ayqyYAPbWfRD6zA2N+haHQCSXXqjJTe/rH6ax0rvMWefCxVKKTuxXTfrRSbtGeCB/4QkpJErrItJxYEIkM3/uM4tvMvH/1DewwWP6gxgX+Faq5VrHVcP1qDXQje8ZM/ajRNdvqZv9begUqPQMckpGKmOWRXZV1/WFN4cbkJdTsf+t6iKTp+9lAyrhcOhPEI/C70SoN20/CFZMN8mDVJMxEeVgUmFD3nDpXLpUS0pzbQsbhiyQuwZaHs4uZMczkozMGgKWuy0IswLQhFl/2F25KHC/ogNrJ4d+W7GFnL+w4argNWcXevbHi+/jXiRcgMgGznAWRSc7Rb7+fIuwGxRLaZhRoH7pdaqtZfdK0VpU= sumner@scarif"
        ];
      };
    };
  };
}
