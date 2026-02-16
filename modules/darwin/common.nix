{ pkgs, vars, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # --- COMMON PACKAGES ---
  # Allow to configure multiple hosts that share a common configuration
  environment.systemPackages = with pkgs; [
    vim
    git
    nixfmt-rfc-style
    syncthing
    rectangle
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
