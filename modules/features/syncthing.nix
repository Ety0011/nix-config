{ ... }:
{
  flake.modules.nixos.syncthing = {
    services.syncthing = {
      enable = true;
      # peers added via collector pattern per host
    };
  };

  flake.modules.darwin.syncthing = {
    services.syncthing = {
      enable = true;
    };
  };
}
