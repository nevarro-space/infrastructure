{ config, lib, pkgs, ... }:
let
  dataDir = "/var/lib/mineshspc";
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  deployment.keys = {
    mineshspc_env.keyCommand = [ "cat" "../infrastructure-secrets/secrets/mineshspc_env" ];
    restic_password_file.keyCommand = [ "cat" "../infrastructure-secrets/secrets/restic_password_file" ];
    restic_environment_file.keyCommand = [ "cat" "../infrastructure-secrets/secrets/restic_environment_file" ];
  };

  networking.hostName = "mineshspc";

  services.nginx = {
    enable = true;

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

  virtualisation.oci-containers.containers = {
    "mineshspc.com" = {
      image = "ghcr.io/coloradoschoolofmines/mineshspc.com:27b05c266304871f91b32f55644c4fcfc9296af4";
      volumes = [ "${dataDir}:/data" ];
      ports = [ "8090:8090" ];
      environmentFiles = [ "/run/keys/mineshspc_env" ];
      environment = {
        MINESHSPC_DOMAIN = "https://mineshspc.com";
        MINESHSPC_HOSTED_BY_HTML = ''
          Hosting provided by <a href="https://nevarro.space" target="_blank">Nevarro LLC</a>.
          Check the <a href="https://status.mineshspc.com/" target="_blank">site status</a>.
        '';
        MINESHSPC_REGISTRATION_ENABLED = "0";
      };
    };
  };
  systemd.services."${config.virtualisation.oci-containers.backend}-mineshspc.com" = {
    after = [ "mineshspc_env-key.service" ];
    partOf = [ "mineshspc_env-key.service" ];
  };

  # Make sure that the working directory is available
  system.activationScripts.makeMinesHSPCDir = lib.stringAfter [ "var" ] ''
    mkdir -p ${dataDir}
  '';

  services.backup = {
    healthcheckId = "e3b7948f-42cd-4571-a400-f77401d7dc56";
    healthcheckPruneId = "197d3821-bbf0-4081-b388-8d9dc1c2f11f";
    backups.mineshspc.path = dataDir;
  };
}
