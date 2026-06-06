{ lib, config, ... }:
let
  profiles = config.users.profiles;
  anyWants = feat: lib.any (u: profiles.${u}.features.${feat}.enable) (lib.attrNames profiles);
in
{
  flake.modules.darwin.direnv =
    { lib, ... }:
    {
      config = lib.mkIf (anyWants "direnv") {
        programs.direnv = {
          enable = true;
          loadInNixShell = true;
          nix-direnv.enable = true;
        };
      };
    };

  flake.modules.nixos.direnv =
    { lib, ... }:
    {
      config = lib.mkIf (anyWants "direnv") {
        programs.direnv = {
          enable = true;
          loadInNixShell = true;
          nix-direnv.enable = true;
        };
      };
    };

  flake.modules.homeManager = lib.genAttrs (lib.attrNames profiles) (
    username:
    lib.mkIf
      (profiles.${username}.features.direnv.enable && profiles.${username}.features.direnv.allowed)
      {
        programs.direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
        };
      }
  );
}
