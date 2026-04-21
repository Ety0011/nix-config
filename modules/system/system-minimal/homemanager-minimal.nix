{ ... }:
{
  # Layer 1 — absolute minimum required for every homeManagerConfiguration.

  flake.modules.homeManager.system-minimal =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      # Derive homeDirectory from username so it is always consistent.
      home.homeDirectory = lib.mkDefault (
        if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}"
      );

      home.stateVersion = "24.11";

      # Always enable home-manager self-management.
      programs.home-manager.enable = true;
    };
}
