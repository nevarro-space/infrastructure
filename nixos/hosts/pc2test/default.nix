{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "pc2test";

  services.pc2 = {
    contestPkg = pkgs.callPackage ../../pkgs/test { };
    server = {
      enable = true;
    };

    wti = {
      enable = true;
      virtualHost = "pc2test.mineshspc.com";
      externalIP = "5.161.216.225";
    };
  };
}
