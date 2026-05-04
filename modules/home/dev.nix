{ self, ... }:
{
  # Aggregator: development tooling.
  # Import this in a user module to get nix dev tools.
  flake.modules.homeManager.dev = {
    imports = with self.modules.homeManager; [
      nixTools
    ];
  };
}
