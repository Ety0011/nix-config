{ ... }:
{
  perSystem =
    { config, ... }:
    {
      treefmt.config = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true; # nix files
        programs.prettier.enable = true; # json, yaml, markdown
        programs.shfmt.enable = true; # shell scripts
      };
      formatter = config.treefmt.build.wrapper;
    };
}
