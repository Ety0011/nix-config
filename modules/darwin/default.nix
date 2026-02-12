{ pkgs, username, hostname, ... }:

{
  imports = [
    ./system.nix
    ./nix.nix
  ];

  # System-wide packages
  environment.systemPackages = with pkgs; [
    vim
  ];

  # Set primary user for system defaults
  system.primaryUser = username;

  # User configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Set hostname
  networking.hostName = hostname;
  networking.computerName = hostname;

  # Used for backwards compatibility
  system.stateVersion = 6;
}
