{ inputs, ... }:
{
  # Make pkgs available in perSystem contexts (e.g. the formatter).
  # The unstable overlay is also applied so perSystem tooling can reach it.
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
