"""Stop hook: Claude may only finish once the project's checks pass.

Runs `scripts/check.sh`, the same checks as CI. They're read-only, so a human's
unfinished work in the tree is never rewritten. On failure, exit 2 hands the
output back to Claude. The tree's state after the last pass is cached in the
git dir, so turns that changed nothing stay instant.
"""

import hashlib
import json
import subprocess
import sys
from pathlib import Path

MAX_OUTPUT = 10_000  # characters of failure output handed to Claude


def git(*args: str) -> bytes:
    return subprocess.run(["git", *args], capture_output=True, check=True).stdout


def tree_state() -> str:
    """Hash of HEAD, uncommitted changes, and untracked files' size and mtime."""
    digest = hashlib.sha256(git("rev-parse", "HEAD"))
    digest.update(git("diff", "HEAD", "--binary"))
    untracked = git("ls-files", "--others", "--exclude-standard", "-z")
    for name in sorted(filter(None, untracked.split(b"\0"))):
        path = Path(name.decode())
        if path.is_file():  # stat, not contents: untracked data files can be big
            stat = path.stat()
            digest.update(b"%s\0%d\0%d" % (name, stat.st_size, stat.st_mtime_ns))
    return digest.hexdigest()


def main() -> int:
    event = json.load(sys.stdin)
    cache = Path(git("rev-parse", "--git-path", "claude-stop-check").decode().strip())
    state = tree_state()
    if cache.is_file() and cache.read_text() == state:
        return 0

    result = subprocess.run(
        ["scripts/check.sh"], check=False, capture_output=True, text=True
    )
    if result.returncode == 0:
        cache.write_text(state)
        return 0

    report = (
        "Checks failed. Fix the failures in files you changed; for failures in"
        " files you didn't touch, tell the user instead of fixing them.\n\n"
        + (result.stdout + result.stderr)[-MAX_OUTPUT:]
    )
    if event.get("stop_hook_active"):
        # Claude already had one retry: let it stop, and tell the human instead
        # of looping on a failure Claude can't fix (e.g. a broken environment).
        print(json.dumps({"systemMessage": report}))
        return 0
    print(report, file=sys.stderr)
    return 2


sys.exit(main())
