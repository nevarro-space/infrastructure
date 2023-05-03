{ config, lib, pkgs, ... }: {
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
      volumes = [ "/var/lib/mineshspc:/data" ];
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
    mkdir -p /var/lib/mineshspc
  '';

  # TODO move this to a generic restic backup service
  systemd.services."restic-backup" =
    let
      resticCmd = "${pkgs.restic}/bin/restic --verbose=3";
      resticBackupScript = paths: exclude: pkgs.writeShellScriptBin "restic-backup" ''
        set -xe

        # Perfrom the backup
        ${resticCmd} backup \
          ${lib.concatStringsSep " " paths} \
          ${lib.concatMapStringsSep " " (e: "-e \"${e}\"") exclude}

        # Make sure that the backup has time to settle before running the check.
        sleep 10

        # Check the validity of the repository.
        ${resticCmd} check
      '';
      script = resticBackupScript [ "/var/lib/mineshspc" ] [ ];
    in
    {
      description = "Run Restic Backup";
      environment = {
        RESTIC_PASSWORD_FILE = "/run/keys/restic_password_file";
        RESTIC_REPOSITORY = "b2:nevarro-backups:mineshspc";
        RESTIC_CACHE_DIR = "/var/cache";
      };
      startAt = "0/2:0"; # Run backup every 2 hours
      serviceConfig = {
        ExecStart = "${script}/bin/restic-backup";
        EnvironmentFile = "/run/keys/restic_environment_file";
        PrivateTmp = true;
        ProtectSystem = true;
        ProtectHome = "read-only";
      };
      # Initialize the repository if it doesn't exist already.
      preStart = ''
        ${resticCmd} snapshots || ${resticCmd} init
      '';
    };
}
