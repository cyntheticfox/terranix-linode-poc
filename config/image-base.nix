{ config, lib, pkgs, modulesDir, ... }: {
  services.openssh.enable = lib.mkForce false;
  users.users.root.password = "Thisisabadpassword123!";

  system.stateVersion = "22.05";
}
