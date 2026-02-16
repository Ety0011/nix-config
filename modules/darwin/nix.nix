{ self, ... }:

{
  # Nix configuration
  nix = {
    settings = {
      # Enable flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    # Garbage collection
    gc = {
      automatic = true;

      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };

      options = "--delete-older-than 7d";
    };
  };
}
