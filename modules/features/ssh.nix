{ ... }:
{
  # NixOS: enable the OpenSSH server so the machine is remotely accessible.
  flake.modules.nixos.ssh = {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        # Disable password auth — use keys only (safer default)
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  # homeManager: SSH client config shared across all users on all platforms.
  flake.modules.homeManager.ssh =
    { ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*" = {
          serverAliveInterval = 60;
          serverAliveCountMax = 3;
        };
      };
    };
}
