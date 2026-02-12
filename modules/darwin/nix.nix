{ self, ... }:

{
  # Nix configuration
  nix = {
    settings = {
      # Enable flakes
      experimental-features = [ "nix-command" "flakes" ];
    };

    # Optimize storage
    optimise.automatic = true;

    # Garbage collection
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 0; Minute = 0; };
      options = "--delete-older-than 30d";
    };
  };

  # Set Git commit hash for darwin-version
  system.configurationRevision = self.rev or self.dirtyRev or null;
}
