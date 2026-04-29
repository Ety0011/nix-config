{ ... }:
let
  settings = {
    enable = true;
    loadInNixShell = true;
    nix-direnv.enable = true;
  };
in
{
  # System-level: required for direnv to work correctly outside home-manager
  # managed shells, e.g. in system-level nix-shell invocations.
  flake.modules.nixos.direnv = {
    programs.direnv = settings;
  };

  flake.modules.darwin.direnv = {
    programs.direnv = settings;
  };

  # homeManager: user-level direnv integration with zsh.
  flake.modules.homeManager.direnv = {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
