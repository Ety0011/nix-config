{ inputs, ... }:
{
  perSystem =
    { system, lib, ... }:
    {
      _module.args.pkgs =
        import (if lib.hasSuffix "darwin" system then inputs.nixpkgs-darwin else inputs.nixpkgs)
          {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              (final: _prev: {
                unstable = import inputs.nixpkgs-unstable {
                  inherit (final) config;
                  inherit (final.stdenv.hostPlatform) system;
                };
              })
            ];
          };
    };
}
