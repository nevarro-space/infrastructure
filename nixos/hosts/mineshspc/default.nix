{ pkgs, ... }:
let minesHSPCDataDir = "/var/lib/mineshspc";
in {
  imports = [ ./hardware-configuration.nix ];

  deployment.keys = {
    mineshspc_env.keyCommand =
      [ "cat" "../infrastructure-secrets/secrets/mineshspc_env" ];
    restic_password_file.keyCommand =
      [ "cat" "../infrastructure-secrets/secrets/restic_password_file" ];
    restic_environment_file.keyCommand =
      [ "cat" "../infrastructure-secrets/secrets/restic_environment_file" ];
  };

  networking.hostName = "mineshspc";
  systemd.network.networks = {
    "10-wan" = {
      matchConfig.MACAddress = "96:00:01:f3:c7:74";
      address = [ "2a01:4ff:f0:abdd::1/64" ];
    };
    "10-nevarronet" = { matchConfig.MACAddress = "86:00:00:3a:eb:6a"; };
  };

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

  systemd.services = let
    yamlFormat = pkgs.formats.yaml { };
    siteConfig = {
      database = {
        type = "sqlite3";
        uri = "${minesHSPCDataDir}/mineshspc.db?_txlock=immediate";
      };
      sendgrid_api_key = "$MINESHSPC_SENDGRID_API_KEY";
      healthcheck_url = "$MINESHSPC_HEALTHCHECK_URL";
      hosted_by_html = ''
        Hosting provided by <a href="https://nevarro.space" target="_blank">Nevarro LLC</a>.
          Check the <a href="https://status.mineshspc.com/" target="_blank">site status</a>.
      '';
      domain = "https://mineshspc.com";

      jwt_secret_key = "$MINESHSPC_JWT_SECRET_KEY";

      recaptcha = {
        site_key = "$MINESHSPC_RECAPTCHA_SITE_KEY";
        secret_key = "$MINESHSPC_RECAPTCHA_SECRET_KEY";
      };

      logging = {
        min_level = "debug";
        writers = [{
          type = "stdout";
          format = "pretty-colored";
        }];
      };
    };
    unsubstituted =
      yamlFormat.generate "mineshspc.com.unsubstituted.config" siteConfig;
  in {
    "mineshspc.com.config" = {
      description = "Mines HSPC website config generation service";
      path = [ pkgs.yq pkgs.envsubst ];
      serviceConfig = {
        Type = "oneshot";

        User = "mineshspc";
        Group = "mineshspc";

        SystemCallFilter = [ "@system-service" ];

        ProtectSystem = "strict";
        ProtectHome = true;

        ReadWritePaths = minesHSPCDataDir;
        StateDirectory = minesHSPCDataDir;
        EnvironmentFile = "/run/keys/mineshspc_env";
      };
      script = ''
        envsubst \
            -o '${minesHSPCDataDir}/config.yaml' \
            -i '${unsubstituted}'
      '';
      restartTriggers = [ unsubstituted ];
    };
    "mineshspc.com" = {
      description = "Mines HSPC Website service";
      requires = [
        "network-online.target"
        "mineshspc_env-key.service"
        "mineshspc.com.config.service"
      ];
      after = [
        "network-online.target"
        "mineshspc_env-key.service"
        "mineshspc.com.config.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        WorkingDirectory = minesHSPCDataDir;
        User = "mineshspc";
        Group = "mineshspc";
        ExecStart =
          "${pkgs.mineshspc}/bin/mineshspc -config ${minesHSPCDataDir}/config.yaml";
        Restart = "on-failure";
        EnvironmentFile = "/run/keys/mineshspc_env";
      };
      restartTriggers = [ unsubstituted ];
    };
  };

  users = {
    users.mineshspc = {
      group = "mineshspc";
      isSystemUser = true;
      home = minesHSPCDataDir;
      createHome = true;
    };
    groups.mineshspc = { };
  };

  services.backup = {
    healthcheckId = "e3b7948f-42cd-4571-a400-f77401d7dc56";
    healthcheckPruneId = "197d3821-bbf0-4081-b388-8d9dc1c2f11f";
    backups.mineshspc.path = minesHSPCDataDir;
  };

  services.healthcheck = {
    enable = true;
    disks = [{
      path = "/";
      threshold = 95;
      checkId = "b05f5eb0-ac9e-480e-982e-85a42a505e02";
    }];
  };
}
