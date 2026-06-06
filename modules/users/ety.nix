{ self, ... }:
let
  username = "ety";
in
{
  users.profiles.${username} = {
    features.git.enable = true;
    features.zsh.enable = true;
    features.ssh.enable = true;
    features.direnv.enable = true;
    features.starship.enable = true;
    features.nixTools.enable = true;
    features.sops.enable = true;
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
      environment.systemPath = [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
      ];
      homebrew.casks = [
        "obs"
        "unity-hub"
        "microsoft-teams"
        "steam"
        "ollama-app"
      ];
      homebrew.brews = [
        "pixi"
        "ccache"
        "poppler"
        "p7zip"
      ];
      home-manager.users.${username} = {
        imports = [ self.modules.homeManager.${username} ];
        programs.zsh.shellAliases.update = "sudo darwin-rebuild switch --flake ~/nix-config";
      };
    };

  flake.modules.nixos.${username} =
    { pkgs, ... }:
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
      home-manager.users.${username} = {
        imports = [ self.modules.homeManager.${username} ];
        programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake ~/nix-config";
      };
    };

  flake.modules.homeManager.${username} =
    { pkgs, ... }:
    {
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
