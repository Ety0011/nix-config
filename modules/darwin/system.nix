{ ... }:

{
  # System configuration
  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      show-recents = false;
      orientation = "bottom";
    };

    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
      ShowPathbar = true;
    };

    # NSGlobalDomain settings
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
  };

  # Keyboard settings
  # keyboard = {
  #   enableKeyMapping = true;
  #   remapCapsLockToEscape = true;
  # };

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";
}
