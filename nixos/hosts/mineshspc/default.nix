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

  systemd.services."mineshspc.com" = {
    description = "Mines HSPC Website service";
    after = [
      "network-online.target"
      "mineshspc_env-key.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      WorkingDirectory = dataDir;
      User = "mineshspc";
      Group = "mineshspc";
      ExecStart = "${pkgs.mineshspc}/bin/mineshspc.com";
      Restart = "on-failure";
      EnvironmentFile = "/run/keys/mineshspc_env";
    };
    environment = {
      MINESHSPC_DOMAIN = "https://mineshspc.com";
      MINESHSPC_HOSTED_BY_HTML = ''
        Hosting provided by <a href="https://nevarro.space" target="_blank">Nevarro LLC</a>.
        Check the <a href="https://status.mineshspc.com/" target="_blank">site status</a>.
      '';
      MINESHSPC_REGISTRATION_ENABLED = "0";
    };
  };

  users = {
    users.mineshspc = {
      group = "mineshspc";
      isSystemUser = true;
      home = dataDir;
      createHome = true;
    };
    groups.mineshspc = { };
  };

  services.backup = {
    healthcheckId = "e3b7948f-42cd-4571-a400-f77401d7dc56";
    healthcheckPruneId = "197d3821-bbf0-4081-b388-8d9dc1c2f11f";
    backups.mineshspc.path = dataDir;
  };

  services.healthcheck = {
    enable = true;
    disks = [
      { path = "/"; threshold = 95; checkId = "b05f5eb0-ac9e-480e-982e-85a42a505e02"; }
    ];
  };
}
