{
  flake.modules.nixos.base.services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  flake.modules.homeManager.base.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*".ServerAliveInterval = 60;
  };
}
