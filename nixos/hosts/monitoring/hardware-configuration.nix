{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5db295ec-a933-4395-b918-ebef6f95d8c3";
    fsType = "ext4";
  };
}
