{ config, ... }: {
  imports = [ ./hardware-configuration.nix ];

  deployment.keys = let
    keyFor = keyname: for: {
      keyCommand = [ "cat" "../infrastructure-secrets/secrets/${keyname}" ];
      user = for;
      group = for;
    };
  in {
    # Backup Secrets
    restic_password_file = keyFor "restic_password_file" "root";
    restic_environment_file = keyFor "restic_environment_file" "root";

    # Matrix Bot Secrets
    maubot_yaml = keyFor "matrix/bots/maubot.yaml" "root";
    meetbot_secret_env = keyFor "matrix/bots/meetbot.env" "meetbot";
    meowlnir_env = keyFor "matrix/meowlnir_env" "meowlnir";
    mscbot_password = keyFor "matrix/bots/mscbot" "msclinkbot";
    standupbot_password = keyFor "matrix/bots/standupbot" "standupbot";

    # Matrix Server Secrets
    nevarro_space_registration_shared_secret =
      keyFor "matrix/registration-shared-secret/nevarro.space" "matrix-synapse";
    module_config =
      keyFor "matrix/module-config/nevarro.space" "matrix-synapse";
    nevarro_space_cleanup_synapse_environment_file =
      keyFor "matrix/cleanup-synapse/nevarro.space" "root";
  };

  networking.hostName = "matrix";
  systemd.network.networks = {
    "10-wan" = {
      matchConfig.MACAddress = "96:00:02:23:cd:a5";
      address = [ "2a01:4ff:f0:ec8::1/64" ];
    };
    "10-nevarronet".matchConfig.MACAddress = "86:00:00:44:d6:83";
  };

  services.healthcheck = {
    enable = true;
    url =
      "https://heartbeat.uptimerobot.com/m798927884-3639c213b4500e152e5af22a56d4c9a655985fd7";
    disks = [
      {
        path = "/";
        threshold = 95;
        url =
          "https://heartbeat.uptimerobot.com/m798927898-8bfee32fcc69ffcd9df419a99a9c068d8126d753";
      }
      {
        path = "/mnt/postgresql-data";
        threshold = 95;
        url =
          "https://heartbeat.uptimerobot.com/m798927906-b2c3fdb9c5e6c8976f5102114931783f84b59297";
      }
    ];
  };

  services.backup = {
    backupCompleteURL =
      "https://heartbeat.uptimerobot.com/m798927916-29b2ae22a7f2eed0332a7173c33764624f47634b";
    pruneCompleteURL =
      "https://heartbeat.uptimerobot.com/m798927922-54c59fccda5de4c32704d116a912c2cbf2b5611f";
  };

  # MSC Link Bot
  services.msclinkbot = {
    enable = true;
    username = "@mscbot:nevarro.space";
    homeserver = "https://matrix.nevarro.space";
    passwordFile = "/run/keys/mscbot_password";
  };

  # Standupbot
  services.standupbot = {
    enable = true;
    username = "@standupbot:nevarro.space";
    homeserver = "https://matrix.nevarro.space";
    passwordFile = "/run/keys/standupbot_password";
  };

  # Meowlnir
  services.meowlnir = {
    enable = true;
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = "nevarro.space";
      };

      meowlnir = {
        id = "meowlnir";
        as_token = "$MEOWLNIR_AS_TOKEN";
        hs_token = "$MEOWLNIR_HS_TOKEN";
        pickle_key = "$MEOWLNIR_PICKLE_KEY";
        management_secret = "$MEOWLNIR_MANAGEMENT_SECRET";
        report_room = "!jbWwxAnPTAvGkjQjXh:nevarro.space";
      };

      antispam.secret = "$MEOWLNIR_ANTISPAM_SECRET";

      synapse_db = {
        type = "postgres";
        uri =
          "postgres://meowlnir:meowlnir@localhost/matrix-synapse?sslmode=disable";
      };
    };
    registration = {
      as_token = "$MEOWLNIR_AS_TOKEN";
      hs_token = "$MEOWLNIR_HS_TOKEN";
      sender_localpart = "mohMex1ro0zaeraimeem";
      namespaces = {
        users = [{
          regex = "@marshal:nevarro.space";
          exclusive = true;
        }];
      };
    };
    environmentFile = "/run/keys/meowlnir_env";
    registerToSynapse = true;
    serviceDependencies =
      [ config.services.matrix-synapse.serviceUnit "meowlnir_env-key.service" ];
  };
  systemd.services.meowlnir.serviceConfig.SupplementaryGroups = [ "keys" ];

  # Maubot
  services.maubot-docker.enable = true;

  # Meetbot
  services.meetbot = {
    enable = true;
    username = "@meetbot:nevarro.space";
    homeserver = "https://matrix.nevarro.space";
    secretEnv = "/run/keys/meetbot_secret_env";
  };

  # Discord <-> Matrix Bridge
  services.mautrix-discord = {
    enable = true;
    homeserver = "https://matrix.nevarro.space";
  } // (import ../../../secrets/matrix/appservices/mautrix-discord.nix);

  # Synapse
  services.matrix-synapse.enable = true;
  services.cleanup-synapse.environmentFile =
    "/run/keys/nevarro_space_cleanup_synapse_environment_file";

  # PosgreSQL
  services.postgresql.enable = true;
  services.postgresql.dataDir =
    "/mnt/postgresql-data/${config.services.postgresql.package.psqlSchema}";
  services.postgresqlBackup.enable = true;
}
