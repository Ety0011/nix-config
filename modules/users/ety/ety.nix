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
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
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
      environment.systemPath = [ "/opt/homebrew/bin" "/opt/homebrew/sbin" ];
      imports = with self.modules.darwin; [ homebrew ];
      homebrew.casks = [
        "obs"
        "unity-hub"
        "microsoft-teams"
        "steam"
        "ollama-app"
      ];
      # CLI tools go here
      homebrew.brews = [
        "pixi"
        "ccache"
        "poppler" # allows vsclaude code to read pdf
        "p7zip"
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
        cli # zsh, git, ssh, direnv, starship
        dev # nixTools
      ];

      home.stateVersion = "24.11";

      programs.git.settings.user = {
        name = "Etienne";
        email = "etienne.orio@orio.ch";
      };

      home.packages = with pkgs; [
        lldb
        rectangle
        claude-code
        opencode
        nodejs
        htop
      ];
    };
}
