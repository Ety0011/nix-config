{ lib, config, ... }:
let
  profiles = config.users.profiles;
in
{
  flake.modules.nixos.ssh =
    { lib, hostProfiles, ... }:
    {
      config =
        lib.mkIf (lib.any (u: hostProfiles.${u}.features.ssh.enable) (lib.attrNames hostProfiles))
          {
            services.openssh = {
              enable = true;
              openFirewall = true;
              settings = {
                PasswordAuthentication = false;
                PermitRootLogin = "no";
              };
            };
          };
    };

  flake.modules.homeManager = lib.genAttrs (lib.attrNames profiles) (
    username:
    lib.mkIf (profiles.${username}.features.ssh.enable) {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*" = {
          serverAliveInterval = 60;
          serverAliveCountMax = 3;
        };
      };
    }
  );
}
