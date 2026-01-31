{ pkgs, ... }:
{
  users.mutableUsers = false;

  users.users.root = {
    shell = pkgs.zsh;

    # Allow all of my computers to SSH in.
    openssh.authorizedKeys.keys = (import ./sumner-pubkeys.nix) ++ (import ./deploy-pubkeys.nix);
  };
}
