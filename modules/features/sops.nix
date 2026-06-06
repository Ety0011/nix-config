{
  inputs,
  lib,
  config,
  ...
}:
let
  profiles = config.users.profiles;
in
{
  flake.modules.darwin.sops =
    { lib, hostProfiles, ... }:
    {
      imports = lib.optional (lib.any (u: hostProfiles.${u}.features.sops.enable) (
        lib.attrNames hostProfiles
      )) inputs.sops-nix.darwinModules.sops;
    };

  flake.modules.nixos.sops =
    { lib, hostProfiles, ... }:
    {
      imports = lib.optional (lib.any (u: hostProfiles.${u}.features.sops.enable) (
        lib.attrNames hostProfiles
      )) inputs.sops-nix.nixosModules.sops;
    };

  flake.modules.homeManager = lib.genAttrs (lib.attrNames profiles) (
    username:
    lib.mkIf (profiles.${username}.features.sops.enable) {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];
    }
  );
}
