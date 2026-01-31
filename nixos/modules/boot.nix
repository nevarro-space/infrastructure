{
  boot = {
    loader.grub.device = "/dev/sda";
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "xen_blkfront"
      "vmw_pvscsi"
    ];
    initrd.kernelModules = [ "nvme" ];
    tmp.cleanOnBoot = true;
    loader.timeout = 10;

    # Enable LISH
    kernelParams = [ "console=ttyS0,19200n8" ];
    loader.grub.extraConfig = ''
      serial --speed=19200 --unit=0 --word=8 --party=no --stop=1;
      terminal_input serial;
      terminal_output serial;
    '';
  };
}
