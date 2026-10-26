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
      # GUI apps stay in Homebrew: they self-update, and macOS privacy grants
      # (camera, mic, screen) survive updates. See docs/adr/0003.
      homebrew.casks = [
        "capslocknodelay"
        "microsoft-teams"
        "obs"
        "obsidian"
      ];
      # Colima's Docker stack integrates better from Homebrew on macOS.
      homebrew.brews = [
        "colima"
        "docker"
        "docker-compose"
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
        unstable.claude-code
        unstable.opencode
        nodejs
        htop
        gh
        pixi
        rclone
        rsync
      ];
    };
}
