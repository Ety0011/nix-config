{ self, ... }:
{
  # Aggregator: CLI tools and shell environment.
  # Import this in a user module to get the full CLI stack at once.
  flake.modules.homeManager.cli = {
    imports = with self.modules.homeManager; [
      zsh
      git
      ssh
      direnv
      starship
    ];
  };
}
