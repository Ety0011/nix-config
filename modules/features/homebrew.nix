{ lib, ... }:
{
  flake.modules.darwin.homebrew =
    { config, ... }:
    {
      options.features.homebrew.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      config = lib.mkIf config.features.homebrew.enable {
        homebrew.enable = true;
        homebrew.onActivation.cleanup = "none";
      };
    };
}
