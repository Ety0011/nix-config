{ lib, config, ... }:
let
  profiles = config.users.profiles;
  anyWants = feat: lib.any (u: profiles.${u}.features.${feat}.enable) (lib.attrNames profiles);
in
{
  flake.modules.nixos.syncthing =
    { lib, ... }:
    {
      config = lib.mkIf (anyWants "syncthing") {
        services.syncthing = {
          enable = true;
          openDefaultPorts = true;
        };
      };
    };
}
