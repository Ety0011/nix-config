# Daily mirror of ~ to the NAS, which keeps its own versions. The `i14-nas`
# remote and its credentials stay in the unmanaged ~/.config/rclone/rclone.conf.
# Home Manager module, imported by the darwin side of users/ety.nix.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  name = "backup-home";
  remote = "i14-nas:home/backup";

  filters = pkgs.writeText "${name}-filters" ''
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
  '';

  backup-home = pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [
      pkgs.coreutils
      pkgs.flock
      pkgs.rclone
    ];
    text = ''
      # Outside the backup: Console.app shows ~/Library/Logs, and a restored
      # Mac starts without the old state.
      log="$HOME/Library/Logs/${name}.log"
      state="$HOME/Library/Application Support/${name}"
      mkdir -p "$state" "$(dirname "$log")"

      note() { echo "$(date '+%Y/%m/%d %H:%M:%S') NOTICE: $*" >>"$log"; }
      notify() {
        /usr/bin/osascript -e "display notification \"$2\" with title \"$1\""
      }

      # One run at a time: launchd and a manual run can overlap.
      exec 9>"$state/lock"
      if ! flock -n 9; then
        echo "${name} is already running" >&2
        exit 0
      fi

      now=$(date +%s)
      last=$(cat "$state/last-success" 2>/dev/null || echo 0)

      # launchd tries hourly; back up once per calendar day.
      if [ "''${1:-}" = --scheduled ] &&
        [ "$(date -d "@$last" +%F)" = "$(date +%F)" ]; then
        exit 0
      fi

      # Errors plus one summary line per run; keep at most ~2 MB.
      if [ -f "$log" ] && (($(wc -c <"$log") > 1048576)); then
        mv "$log" "$log.1"
      fi

      progress=()
      if [ -t 1 ]; then progress=(--progress); fi

      # Away from home the NAS is unreachable: log one line, not every retry.
      if ! rclone lsf ${remote} --max-depth 1 --dirs-only \
        --contimeout 10s --low-level-retries 1 >/dev/null 2>&1; then
        note "NAS unreachable, skipped"
      elif rclone sync "$HOME" ${remote}/${osConfig.networking.hostName} \
        --filter-from ${filters} \
        --modify-window 1s \
        --transfers 4 \
        --checkers 8 \
        --links \
        --log-file "$log" \
        --log-level NOTICE \
        --stats 24h \
        --stats-one-line \
        --stats-log-level NOTICE \
        "''${progress[@]}"; then
        echo "$now" >"$state/last-success"
        if [ -f "$state/last-warning" ]; then
          rm "$state/last-warning"
          notify "Backup to NAS is working again" "Last backup: just now."
        fi
        exit 0
      fi

      # Failures are normal away from home. Warn only when the last success
      # is over 3 days old, at most once a day.
      warned=$(cat "$state/last-warning" 2>/dev/null || echo 0)
      if ((now - last > 3 * 86400 && now - warned > 86400)); then
        if ((last == 0)); then
          when="No successful backup yet."
        else
          when="Last success $(((now - last) / 86400)) days ago."
        fi
        notify "Backup to NAS is stale" "$when See ~/Library/Logs/${name}.log"
        echo "$now" >"$state/last-warning"
      fi
      exit 1
    '';
  };
in
{
  home.packages = [ backup-home ];

  launchd.agents.${name} = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/caffeinate"
        "-is"
        (lib.getExe backup-home)
        "--scheduled"
      ];
      # Hourly, plus at login; a run missed during sleep fires on wake.
      StartInterval = 3600;
      RunAtLoad = true;
      ProcessType = "Background";
      # The script's own errors (rclone logs to the same file itself).
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/${name}.log";
    };
  };
}
