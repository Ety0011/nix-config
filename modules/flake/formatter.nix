{
  perSystem =
    { config, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        # sops writes these files; reformatting them churns every edit.
        settings.global.excludes = [ "secrets/*" ];
        programs.nixfmt.enable = true;
        programs.prettier.enable = true;
        programs.shfmt.enable = true;
        programs.deadnix.enable = true;
        programs.statix = {
          enable = true;
          # Feature files repeat `flake.modules.<class>` keys by design.
          disabled-lints = [ "repeated_keys" ];
        };
      };
      formatter = config.treefmt.build.wrapper;
    };
}
