{ lib, config, ... }:
let
  profiles = config.users.profiles;
in
{
  flake.modules.darwin.zsh =
    { lib, hostProfiles, ... }:
    {
      config =
        lib.mkIf (lib.any (u: hostProfiles.${u}.features.zsh.enable) (lib.attrNames hostProfiles))
          {
            programs.zsh.enable = true;
          };
    };

  flake.modules.nixos.zsh =
    { lib, hostProfiles, ... }:
    {
      config =
        lib.mkIf (lib.any (u: hostProfiles.${u}.features.zsh.enable) (lib.attrNames hostProfiles))
          {
            programs.zsh.enable = true;
          };
    };

  flake.modules.homeManager = lib.genAttrs (lib.attrNames profiles) (
    username:
    lib.mkIf (profiles.${username}.features.zsh.enable && profiles.${username}.features.zsh.allowed) {
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        enableCompletion = true;
        history = {
          size = 10000;
          ignoreDups = true;
          ignoreSpace = true;
          share = true;
        };
      };
    }
  );
}
