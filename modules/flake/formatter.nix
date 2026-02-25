{ ... }:
{
  perSystem =
    { config, ... }:
    {
      treefmt.config = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true; # nix formatter
        programs.prettier.enable = true; # json, yaml, md
        programs.shfmt.enable = true; # shell scripts
      };
      formatter = config.treefmt.build.wrapper;
    };
}
