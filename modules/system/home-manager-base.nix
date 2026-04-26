{ ... }:
{
  flake.modules.homeManager.base =
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
