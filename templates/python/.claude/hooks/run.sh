#!/usr/bin/env bash
# Runs a hook script with the project's venv first on PATH: hooks don't inherit
# direnv's environment, and ruff, basedpyright and pytest all live in .venv.
cd "$CLAUDE_PROJECT_DIR" || exit 1
if [ ! -x .venv/bin/python ]; then
  # Without the venv the checks would be skipped silently: tell the human.
  echo '{"systemMessage": "Claude Code hooks did not run: no .venv. Run `direnv allow` (Nix setup) or `uv sync`."}'
  exit 0
fi
PATH="$PWD/.venv/bin:$PATH" exec .venv/bin/python ".claude/hooks/$1"
