{ config, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.darwin.ety = {
    users.users.ety.home = "/Users/ety";
    system.primaryUser = "ety";
    # GUI apps stay in Homebrew: they self-update, and macOS privacy grants
    # (camera, mic, screen) survive updates. See docs/adr/0003.
    # Apps worth reinstalling on a new Mac; games and one-offs stay manual.
    homebrew.casks = [
      "capslocknodelay"
      "discord"
      "emclient"
      "firefox"
      "localsend"
      "microsoft-teams"
      "nordvpn"
      "obs"
      "obsidian"
      "openmtp"
      "tailscale-app"
      "visual-studio-code"
      "vorssaint"
      "whatsapp"
    ];
    # Colima's Docker stack integrates better from Homebrew on macOS.
    homebrew.brews = [
      "colima"
      "docker"
      "docker-compose"
    ];
    home-manager.users.ety = {
      imports = [ homeManager.ety ];
      # `colima start` writes this file; it makes `ssh colima` work.
      programs.ssh.includes = [ "~/.colima/ssh_config" ];
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
