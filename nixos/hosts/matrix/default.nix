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

  services.healthcheck = {
    enable = true;
    checkId = "d7eae3e9-de4c-452b-9142-60e7831874c3";
    disks = [ "/" ];
  };
}
