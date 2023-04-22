{
  nix.gc = {
    automatic = true;
    randomizedDelaySec = "45min";
    options = "--delete-older-than 30d";
  };
}
