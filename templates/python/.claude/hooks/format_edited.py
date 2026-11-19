"""PostToolUse hook: format the file Claude just edited with ruff.

Formatting only: `ruff check --fix` here would delete an import Claude added
one edit before the code that uses it. Only files inside the project are
formatted, and ruff's excludes still apply to the explicit path.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

event = json.load(sys.stdin)
tool_input = event.get("tool_input", {})
path = tool_input.get("file_path") or tool_input.get("notebook_path")
project = Path(os.environ["CLAUDE_PROJECT_DIR"]).resolve()
if (
    path
    and path.endswith((".py", ".pyi", ".ipynb"))
    and Path(path).resolve().is_relative_to(project)
):
    subprocess.run(["ruff", "format", "--quiet", "--force-exclude", path], check=False)
