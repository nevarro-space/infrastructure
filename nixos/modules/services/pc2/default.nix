{ lib, pkgs, ... }: with lib; {
  imports = [
    ./server.nix
    ./wti.nix
  ];

  options.services.pc2 = {
    contestPkg = mkOption {
      type = types.package;
      description = "A package containing the contest definition to use";
    };
  };

  config = {
    users.groups.pc2 = { };
  };
}
