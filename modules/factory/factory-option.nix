{ lib, ... }:
{
  # Storage for Factory Aspect functions.
  # Each factory is a function that returns a set of partial module configs,
  # called at the use-site to stamp out boilerplate (e.g. user accounts).
  options.flake.factory = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
    description = "Factory functions for generating reusable module fragments.";
  };
}
