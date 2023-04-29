{ modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/cf27e80b-f418-472e-8846-36073a76a628";
    fsType = "ext4";
  };
}
