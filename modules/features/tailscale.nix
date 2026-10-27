{
  # helios runs the tailscale-app cask; this joins typhon to the same tailnet.
  flake.modules.nixos.base.services.tailscale.enable = true;
}
