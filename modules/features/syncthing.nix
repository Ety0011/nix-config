{ ... }:
{
  flake.modules.nixos.syncthing =
    { lib, hostProfiles, ... }:
    {
      config =
        lib.mkIf (lib.any (u: hostProfiles.${u}.features.syncthing.enable) (lib.attrNames hostProfiles))
          {
            services.syncthing = {
              enable = true;
              openDefaultPorts = true;
            };
          };
    };
}
