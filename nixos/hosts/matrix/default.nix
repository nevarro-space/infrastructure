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
    mscbot_password = keyFor "matrix/bots/mscbot" "msclinkbot";
    chessbot_password = keyFor "matrix/bots/chessbot" "matrix-chessbot";
    standupbot_password = keyFor "matrix/bots/standupbot" "standupbot";
    meowlnir_env = keyFor "matrix/meowlnir_env" "meowlnir";
    github_maubot_secrets_yaml =
      keyFor "matrix/bots/github.yaml" "maubot-github";
    echobot_maubot_secrets_yaml =
      keyFor "matrix/bots/echobot.yaml" "maubot-echo";
    meetbot_secret_env = keyFor "matrix/bots/meetbot.env" "meetbot";

    # Matrix Server Secrets
    nevarro_space_registration_shared_secret =
      keyFor "matrix/registration-shared-secret/nevarro.space" "matrix-synapse";
    nevarro_space_shared_secret_auth =
      keyFor "matrix/shared-secret-auth/nevarro.space" "matrix-synapse";
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
    checkId = "d7eae3e9-de4c-452b-9142-60e7831874c3";
    disks = [
      {
        path = "/";
        threshold = 95;
        checkId = "5406129d-1352-4a24-b2db-6daa0c0a3d8f";
      }
      {
        path = "/mnt/postgresql-data";
        threshold = 95;
        checkId = "2b04d70f-f432-4359-aab3-f0d2ba6d8995";
      }
    ];
  };

  services.backup = {
    healthcheckId = "a60db84a-ace2-411f-89b7-961982823c60";
    healthcheckPruneId = "3d6709f9-0d86-44fc-805f-e1ad496e7006";
  };

  # Chessbot
  services.matrix-chessbot = {
    enable = true;
    username = "@chessbot:nevarro.space";
    homeserver = "https://matrix.nevarro.space";
    passwordFile = "/run/keys/chessbot_password";
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

  # GitHub Maubot
  services.maubot-github = {
    enable = true;
    username = "@github:nevarro.space";
    homeserver = "https://matrix.nevarro.space";
    publicUrl = "https://matrix.nevarro.space";
    secretYAML = "/run/keys/github_maubot_secrets_yaml";
  };

  # Echo Maubot
  services.maubot-echo = {
    enable = true;
    username = "@ping:nevarro.space";
    homeserver = "https://matrix.nevarro.space";
    secretYAML = "/run/keys/echobot_maubot_secrets_yaml";
  };

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
