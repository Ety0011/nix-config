{ self, ... }:
let
  username = "ety";
in
{
  flake.modules.nixos.${username} =
    { lib, pkgs, ... }:
    {
      users.users.${username} = {
        isNormalUser = true;
        home = "/home/${username}";
        extraGroups = [ "networkmanager" "wheel" ];
        shell = pkgs.zsh;
      };
      home-manager.users.${username}.imports = [
        self.modules.homeManager.${username}
      ];
    };

  flake.modules.darwin.${username} =
    { pkgs, ... }:
    {
      users.users.${username} = {
        name = username;
        home = "/Users/${username}";
        shell = pkgs.zsh;
      };
      system.primaryUser = username;
      imports = with self.modules.darwin; [ homebrew ];
      homebrew.casks = [
        "obs"
        "unity-hub"
        "microsoft-teams"
      ];
      home-manager.users.${username}.imports = [
        self.modules.homeManager.${username}
      ];
    };

  flake.modules.homeManager.${username} =
    { pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        base
        sops
        ssh
        zsh
        git
        direnv
        starship
        nixTools
      ];

      home.stateVersion = "24.11";

      programs.git.settings.user = {
        name = "Etienne";
        email = "etienne.orio@orio.ch";
      };

      home.packages = with pkgs; [
        lldb
        rectangle
      ];
    };
}
