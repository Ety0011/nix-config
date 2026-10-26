{ config, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.darwin.ety =
    { pkgs, ... }:
    {
      users.users.ety = {
        name = "ety";
        home = "/Users/ety";
        shell = pkgs.zsh;
      };
      system.primaryUser = "ety";
      homebrew.casks = [
        "capslocknodelay"
        "microsoft-teams"
        "obs"
        "obsidian"
        "steam"
        "unity-hub"
      ];
      homebrew.brews = [
        "ccache"
        "colima"
        "docker"
        "docker-compose"
        "fpart"
        "gh"
        "p7zip"
        "pixi"
        "poppler"
        "python@3.14"
        "rclone"
        "ripgrep"
        "rsync"
      ];
      home-manager.users.ety = {
        imports = [ homeManager.ety ];
        home.packages = [ pkgs.rectangle ];
      };
    };

  flake.modules.nixos.ety =
    { pkgs, ... }:
    {
      users.users.ety = {
        isNormalUser = true;
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        shell = pkgs.zsh;
      };
      home-manager.users.ety.imports = [ homeManager.ety ];
    };

  flake.modules.homeManager.ety =
    { pkgs, ... }:
    {
      programs.git.settings.user = {
        name = "Etienne";
        email = "etienne.orio@orio.ch";
      };
      home.packages = with pkgs; [
        lldb
        claude-code
        opencode
        nodejs
        htop
      ];
    };
}
