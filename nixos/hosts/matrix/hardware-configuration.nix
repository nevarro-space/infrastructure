{ modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/cf27e80b-f418-472e-8846-36073a76a628";
      fsType = "ext4";
    };
    "/mnt/postgresql-data" = {
      device = "/dev/disk/by-id/scsi-0HC_Volume_31815425";
      fsType = "ext4";
    };
  };
}
