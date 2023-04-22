{
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";
}
