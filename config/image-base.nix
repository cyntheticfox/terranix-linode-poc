{ config, lib, pkgs, modulesDir, ... }: {
  services.openssh.enable = lib.mkForce false;

  system.stateVersion = "22.05";
}
