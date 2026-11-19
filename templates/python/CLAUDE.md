<!-- Template setup, once (then delete this comment):
1. `uv init`, then `uv add --dev ruff basedpyright pytest`.
2. In pyproject.toml, under [tool.uv]: `required-version = "==<uv --version>"`
   (the uv the Nix shell provides; setup-uv in CI reads it).
3. `direnv allow`, open Claude Code, accept the folder trust prompt, then
   `claude plugin install mattpocock-skills@mattpocock --scope project`.
4. Run `/setup-matt-pocock-skills` (issue tracker, labels, domain docs).
-->

# <project name>

<One paragraph: what this project is, and where its spec lives.>

## Commands

- Environment: `direnv allow`. Add dependencies with `uv add` /
  `uv add --dev`, never pip; commit `uv.lock` with `pyproject.toml`.
- Checks: `uv run scripts/check.sh` (ruff, basedpyright, pytest), the same as
  CI. The Stop hook runs it, and you can't finish while it fails.
- One test: `uv run pytest tests/test_x.py::test_name`.

## Rules

<Only what Claude can't learn from the code: hard constraints, things never
to do.>

## Workflow

- Branch, then merge to `main` through a PR with passing CI.
- Before opening a PR, run mattpocock `code-review`, `/code-review` and
  `/simplify`, and tick them in the PR template.
- A hook formats every file you edit with ruff.

## Gotchas

<Anything Claude got wrong twice.>
