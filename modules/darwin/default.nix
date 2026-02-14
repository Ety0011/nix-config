{ pkgs, vars, ... }:

# TODO
# This handle the common configuration to all hosts.
# I suggest to remove everything and move it to another file like "common-configuration.nix" and use a default.nix to import
# But for now it's okay
{
  imports = [
    ./system.nix
    ./nix.nix
  ];

  # --- COMMON PACKAGES ---
  # Allow to configure multiple hosts that share a common configuration
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # --- UNIVERSAL LOGIC ---

  # Set primary user
  system.primaryUser = vars.user;

  users.users.${vars.user} = {
    name = vars.user;
    home = "/Users/${vars.user}";
  };

  # Set hostname dynamically from the 'vars' passed by flake.nix
  networking.hostName = vars.hostname;
  networking.computerName = vars.hostname;
}
