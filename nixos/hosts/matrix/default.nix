{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  deployment.keys = {
    mscbot_password = {
      keyCommand = [ "cat" "../infrastructure-secrets/secrets/matrix/bots/mscbot" ];
      user = "msclinkbot";
      group = "msclinkbot";
    };
  };

  networking.hostName = "matrix2";

  # MSC Link Bot
  services.msclinkbot = {
    enable = true;
    homeserver = "https://matrix.nevarro.space";
    passwordFile = "/run/keys/mscbot_password";
  };
}
