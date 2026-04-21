{ ... }:
{
  flake.modules.nixos.syncthing = {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      # peers and folders are configured per-host via the host module
    };
  };

  flake.modules.darwin.syncthing = {
    services.syncthing = {
      enable = true;
    };
  };
}
