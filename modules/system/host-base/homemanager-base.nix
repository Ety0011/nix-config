{ ... }:
{
  # Structural minimum for every homeManager configuration.
  # This is not a user preference preset — it only wires the scaffolding
  # that home-manager itself requires to function.

  flake.modules.homeManager.hm-base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.homeDirectory = lib.mkDefault (
        if pkgs.stdenv.isDarwin
        then "/Users/${config.home.username}"
        else "/home/${config.home.username}"
      );

      home.stateVersion = "24.11";

      programs.home-manager.enable = true;
    };
}
