#!/usr/bin/env bash
# The project's checks: the one list CI, the Claude Stop hook and people run.
# Run it as `uv run scripts/check.sh` so the tools come from the locked venv.
# Every check runs even after a failure, so one run shows everything to fix,
# and only failing checks print their output.
status=0
for check in "ruff format --check" "ruff check" "basedpyright" "pytest -q"; do
  output=$($check 2>&1) # unquoted on purpose: split into arguments
  code=$?
  # pytest exits 5 when no tests exist: a new project starts with none.
  # Delete this exception once the first test is committed.
  if [ $code -eq 0 ] || { [ "$check" = "pytest -q" ] && [ $code -eq 5 ]; }; then
    echo "ok: $check"
  else
    printf 'FAILED: %s\n%s\n\n' "$check" "$output"
    status=1
  fi
done
exit $status
