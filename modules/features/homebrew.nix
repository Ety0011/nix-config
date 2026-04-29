{ ... }:
{
  # Base homebrew config — shared defaults for all darwin hosts.
  flake.modules.darwin.homebrew = {
    homebrew = {
      enable = true;
      onActivation.cleanup = "zap";
    };
  };
}
