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
    home-manager.users.ety =
      { lib, pkgs, ... }:
      let
        # Daily mirror of ~ to the NAS, which keeps its own versions. The
        # `i14-nas` remote and its credentials stay in the unmanaged
        # ~/.config/rclone/rclone.conf.
        backup = pkgs.writeShellApplication {
          name = "backup-helios";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.rclone
          ];
          text = ''
            # ~/Library/Logs shows up in Console.app and is outside the backup.
            # NOTICE logs errors plus one summary line per run.
            log="$HOME/Library/Logs/backup-helios.log"
            state="$HOME/.local/state/backup-helios"
            mkdir -p "$state"
            now=$(date +%s)
            last=$(cat "$state/last-success" 2>/dev/null || echo 0)

            # launchd tries hourly; one success a day is enough.
            if [ "''${1:-}" = --scheduled ] && ((now - last < 86400)); then
              exit 0
            fi

            if rclone sync "$HOME" i14-nas:home/backup/helios \
              --filter-from ${pkgs.writeText "backup-helios-filters" ''
                - .DS_Store
                + /Library/LaunchAgents/**
                - /Library/**
                - /Documents/games/**
                - /Documents/projects/**
                - /.ssh/agent/**
                + /.ssh/**
                + /.local/**
                - /.*/**
                - .*
              ''} \
              --contimeout 15s \
              --modify-window 1s \
              --transfers 4 \
              --checkers 8 \
              --links \
              --metadata \
              --fast-list \
              --log-file "$log" \
              --log-level NOTICE \
              --stats 24h \
              --stats-one-line \
              --stats-log-level NOTICE; then
              echo "$now" >"$state/last-success"
              exit 0
            fi

            # Failures are normal away from home. Warn only when the last
            # success is over 3 days old, at most once a day.
            warned=$(cat "$state/last-warning" 2>/dev/null || echo 0)
            if ((now - last > 3 * 86400 && now - warned > 86400)); then
              if ((last == 0)); then
                when="No successful backup yet."
              else
                when="Last success $(((now - last) / 86400)) days ago."
              fi
              /usr/bin/osascript -e "display notification \"$when See ~/Library/Logs/backup-helios.log\" with title \"Backup to NAS is stale\""
              echo "$now" >"$state/last-warning"
            fi
            exit 1
          '';
        };
      in
      {
        imports = [ homeManager.ety ];
        # `colima start` writes this file; it makes `ssh colima` work.
        programs.ssh.includes = [ "~/.colima/ssh_config" ];
        home.packages = [ backup ];
        launchd.agents.backup = {
          enable = true;
          config = {
            ProgramArguments = [
              "/usr/bin/caffeinate"
              "-is"
              (lib.getExe backup)
              "--scheduled"
            ];
            # Hourly, plus at login; a run missed during sleep fires on wake.
            StartInterval = 3600;
            RunAtLoad = true;
            ProcessType = "Background";
          };
        };
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
        # helios's key. The password is set once with `passwd` at install
        # (see modules/hosts/typhon/default.nix).
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIz9aScitAwf5r+6/Aaoxw6q4rLSVq5ij/mK48th5T1z ety@helios"
        ];
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
        pixi
        rclone
      ];
    };
}
