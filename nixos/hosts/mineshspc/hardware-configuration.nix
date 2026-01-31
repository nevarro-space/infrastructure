{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1f547165-7127-4c78-a80b-2b46fbcf78ac";
    fsType = "ext4";
  };
}
