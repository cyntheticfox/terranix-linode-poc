{ config, lib, pkgs, modulesDir, ... }: {
  services.openssh.enable = lib.mkForce false;
  # Set the following in terraform instead
  users.users.root.password = null;
}
