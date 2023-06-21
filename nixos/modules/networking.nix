{
  networking = {
    domain = "nevarro.space";
    nameservers = [ "8.8.8.8" ];

    dhcpcd.enable = true;
    usePredictableInterfaceNames = false;
    interfaces.eth0.useDHCP = true;
  };
}
