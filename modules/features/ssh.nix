{ lib, config, ... }:
let
  profiles = config.users.profiles;
  anyWants = feat: lib.any (u: profiles.${u}.features.${feat}.enable) (lib.attrNames profiles);
in
{
  flake.modules.nixos.ssh =
    { lib, ... }:
    {
      config = lib.mkIf (anyWants "ssh") {
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
    lib.mkIf (profiles.${username}.features.ssh.enable && profiles.${username}.features.ssh.allowed) {
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
