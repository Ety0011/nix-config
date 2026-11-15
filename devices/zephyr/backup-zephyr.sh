#!/data/data/com.termux/files/usr/bin/bash
# Daily mirror of zephyr's shared storage to the NAS, which keeps its own
# versions. Termux itself goes in as a tarball of ~ plus the list of
# installed packages; usr/ is not copied, `pkg install` rebuilds it.
#
# Run by hand: backs up now, with live progress. Run by a scheduler (no
# terminal, e.g. termux-job-scheduler every hour): once per calendar day.
# Needs the `i14-nas` remote in ~/.config/rclone/rclone.conf. Notifications
# need the Termux:API app and `pkg install termux-api`; without them it only
# logs.

set -euo pipefail

name=backup-zephyr
share=i14-nas:private-ety
remote=$share/backup/zephyr

shared=$(readlink -f "$HOME/storage/shared")
export_dir=$shared/Documents/termux-backup
state=$HOME/.local/state/$name
log=$state/$name.log
mkdir -p "$state" "$export_dir"

# Back up what you made; skip what can be downloaded or rebuilt. First match
# wins. Paths starting with / are relative to shared storage.
filters='
# Android clutter: thumbnail caches, trash and half-written files
- .thumbnails/**
- .trashed-*
- .pending-*
# App data is the apps own business, except WhatsApp media and its chat
# database backups. Statuses expire after 24 hours.
- /Android/media/com.whatsapp/WhatsApp/Media/.Statuses/**
+ /Android/media/com.whatsapp/**
- /Android/**
'

note() { echo "$(date '+%Y/%m/%d %H:%M:%S') NOTICE: $*" >>"$log"; }
notify() {
  if command -v termux-notification >/dev/null; then
    # Without the Termux:API app this waits forever for a reply.
    timeout 10 termux-notification --id "$name" --title "$1" --content "$2" ||
      true
  fi
}

# One run at a time: a scheduled and a manual run can overlap.
lock=$state/lock
if [ -f "$lock" ] && kill -0 "$(cat "$lock")" 2>/dev/null; then
  echo "$name is already running" >&2
  exit 0
fi
echo $$ >"$lock"

# Keep the CPU awake while running; Android suspends Termux otherwise.
if command -v termux-wake-lock >/dev/null; then
  termux-wake-lock
  trap 'termux-wake-unlock; rm -f "$lock"' EXIT
else
  trap 'rm -f "$lock"' EXIT
fi

interactive=false
[ -t 1 ] && interactive=true

now=$(date +%s)
last=$(cat "$state/last-success" 2>/dev/null || echo 0)

# A scheduler tries often; back up once per calendar day.
if ! $interactive && [ "$(date -d "@$last" +%F)" = "$(date +%F)" ]; then
  exit 0
fi

# Errors plus one summary line per run; keep at most ~2 MB.
if [ -f "$log" ] && (($(wc -c <"$log") > 1048576)); then
  mv "$log" "$log.1"
fi

# By hand: live progress. rclone redraws it every --stats, so override the
# 24h below, and keep those per-tick stats lines out of the log.
progress=()
if $interactive; then
  progress=(--progress --stats 500ms --stats-log-level INFO)
fi

stale() {
  # Failures are normal away from home. Warn only when the last success is
  # over 3 days old, at most once a day.
  warned=$(cat "$state/last-warning" 2>/dev/null || echo 0)
  if ((now - last > 3 * 86400 && now - warned > 86400)); then
    if ((last == 0)); then
      when="No successful backup yet."
    else
      when="Last success $(((now - last) / 86400)) days ago."
    fi
    notify "Backup to NAS is stale" "$when See $log"
    echo "$now" >"$state/last-warning"
  fi
  exit 1
}

# Away from home the NAS is unreachable: log one line, not every retry.
# Probe the share, not $remote: sync creates that on the first run.
if ! rclone lsf "$share" --max-depth 1 --dirs-only \
  --contimeout 10s --low-level-retries 1 >/dev/null 2>&1; then
  note "NAS unreachable, skipped"
  $interactive && echo "NAS unreachable, skipped" >&2
  stale
fi

# Termux: ~ minus caches, and the packages to reinstall. Write to a temporary
# file and rename, so a failed run never syncs a truncated tarball. GNU tar
# exits 1 when a file changed while being read; that is fine here.
pkg_list=$export_dir/termux-packages.txt
apt-mark showmanual >"$pkg_list.tmp" && mv "$pkg_list.tmp" "$pkg_list"
tarball=$export_dir/termux-home.tar.gz
rc=0
tar -czf "$tarball.tmp" -C /data/data/com.termux/files \
  --exclude=./home/.cache \
  --exclude="./home/.local/state/$name" \
  --exclude=node_modules \
  --exclude=.venv \
  --exclude=__pycache__ \
  ./home 2>>"$log" || rc=$?
if ((rc > 1)); then
  rm -f "$tarball.tmp"
  note "tar of ~ failed (exit $rc)"
  stale
fi
mv "$tarball.tmp" "$tarball"

if rclone sync "$shared" "$remote" \
  --filter-from <(printf '%s' "$filters") \
  --delete-excluded \
  --modify-window 1s \
  --links \
  --log-file "$log" \
  --log-level NOTICE \
  --stats 24h \
  --stats-one-line \
  --stats-log-level NOTICE \
  "${progress[@]}"; then
  echo "$now" >"$state/last-success"
  if [ -f "$state/last-warning" ]; then
    rm "$state/last-warning"
    notify "Backup to NAS is working again" "Last backup: just now."
  fi
  exit 0
fi
stale
