{ inputs, ... }:
{
  # Defines pkgs for all perSystem contexts with allowUnfree and the
  # unstable overlay. withSystem in base.nix threads this same pkgs
  # instance into every host config — no need to re-import nixpkgs-unstable
  # separately inside each platform base module.
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (final: _prev: {
            unstable = import inputs.nixpkgs-unstable {
              inherit (final) config system;
            };
          })
        ];
      };
    };
}
