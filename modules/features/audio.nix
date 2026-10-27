{
  # Plasma's display manager already enables PipeWire with ALSA and Pulse.
  flake.modules.nixos.desktop.security.rtkit.enable = true;
}
