{ lib, config, ... }:
let
  profiles = config.users.profiles;
in
{
  flake.modules.darwin.direnv =
    { lib, hostProfiles, ... }:
    {
      config =
        lib.mkIf (lib.any (u: hostProfiles.${u}.features.direnv.enable) (lib.attrNames hostProfiles))
          {
            programs.direnv = {
              enable = true;
              loadInNixShell = true;
              nix-direnv.enable = true;
            };
          };
    };

  flake.modules.nixos.direnv =
    { lib, hostProfiles, ... }:
    {
      config =
        lib.mkIf (lib.any (u: hostProfiles.${u}.features.direnv.enable) (lib.attrNames hostProfiles))
          {
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
