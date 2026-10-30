# Per-project dev environments: Python

Research date: 2026-10-30. The language-independent pattern (templates, the project flake, direnv,
CI rule, pinning) is in [dev-env.md](dev-env.md); this file is the Python half. Method: each
candidate's own repo or docs were read at the commits in §14 (uv, uv2nix, nix-ld, basedpyright, ty,
the VS Code extensions, setup-uv). The template was tested end to end on helios in the scratchpad
(§10) [local]. "Fact" statements carry a citation; **Assessment** marks my judgement. Familiarity
was not used as a reason for any pick.

---

## 1. TL;DR

- **Nix supplies only `uv`. uv supplies Python and every Python dependency**, from
  `.python-version`, `pyproject.toml` and `uv.lock`.
- **The Python interpreter comes from uv (python-build-standalone), not from nixpkgs.** This
  reverses the obvious Nix choice, and I tested both (§4). Reasons, all on merit:
  1. CI (`astral-sh/setup-uv`) and collaborators without Nix get the same interpreter build that
     you use locally [setup-uv] [local].
  2. On darwin the dev shell is 133 MiB instead of 1.4 GiB, because nixpkgs' Python pulls in
     clang and the Apple SDK [local].
  3. uv's Python includes tkinter; nixpkgs' `python313` does not [local].
  4. On typhon, prebuilt Linux wheels work through the `nix-ld` you already enable. A nixpkgs
     Python ignores nix-ld and needs an `LD_LIBRARY_PATH` per project [nixld-readme#L162-178].
- **Tools are pinned by `uv.lock`:** ruff (format and lint), basedpyright (types) and pytest, as a
  uv `dev` group. The VS Code ruff and basedpyright extensions use those same binaries from
  `.venv` by default, so editor, terminal and CI agree [ruff-vscode] [bp-vscode].
- **CI: `setup-uv` on `ubuntu-latest`, no Nix** (§7).
- **Runner-ups:** the nixpkgs-Python variant (§4.3, tested, full file in §9.4); pixi for
  conda-forge or ROS stacks, as you already do for robotics; uv2nix to ship an app with Nix (§11).

---

## 2. How you work in Python today (evidence)

All read-only on 2026-10-30 [local]; secret values in `.envrc` files were not read.

- **Five Python projects use the-nix-way/dev-templates `python` template verbatim:** pip plus
  `venvShellHook`, nixpkgs from FlakeHub's rolling `0.1`, Python 3.13 [dt-python#L4]
  [dt-python#L59-94]. They are `silcrst-team`, `spotify_to_ytmusic`, `whiteboard-transcriber-main`,
  `engineering-AI-systems` and `natural-language-processing`. History has
  `nix flake init --template github:the-nix-way/dev-templates#python` [local].
- **No Python lockfile anywhere.** There is no `uv.lock`, and dependencies come from
  `pip install -r requirements.txt` or `pip install .` (203 `pip install` lines in history, 0 `uv`
  lines) [local]. Each `.venv` points into `/nix/store/…-python3-3.13.x` [local].
- **One team repo has non-Nix collaborators:** `silcrst-team` is `vivo0/silcrst-team`, and its
  `pyproject.toml` mentions another author's branch. It uses mypy strict and has extras
  `dev = [pytest, mypy]` and `torch` [local].
- **VS Code has** `ms-python.python`, Pylance, `ms-python.vscode-python-envs`,
  `charliermarsh.ruff` and `mkhl.direnv` installed [local].

---

## 3. Candidates and activity

| Candidate               | Stars | Last push  | Latest                                         | Role                         |
| ----------------------- | ----- | ---------- | ---------------------------------------------- | ---------------------------- |
| astral-sh/uv            | 91k   | 2026-10-30 | 0.13.6 (unstable 0.13.4/0.13.5, 26.05 0.11.21) | Python and dependencies      |
| pyproject-nix/uv2nix    | 790   | 2026-10-29 | no releases                                    | alternative (Nix-built venv) |
| prefix-dev/pixi         | 7.9k  | 2026-10-30 | v0.83.0 (26.05 has 0.68.1)                     | alternative (conda)          |
| astral-sh/ruff          | 50k   | 2026-10-30 | 0.17.3                                         | format and lint              |
| DetachHead/basedpyright | 3.6k  | 2026-10-28 | v1.40.2                                        | type checker                 |
| astral-sh/ty            | 20k   | 2026-10-29 | 0.0.95 (beta)                                  | type checker (later)         |
| cachix/git-hooks.nix    | 877   | 2026-10-26 | n/a                                            | hooks (skipped)              |
| astral-sh/setup-uv      | 898   | 2026-10-28 | v10.3.3                                        | CI                           |

Sources: [gh-meta] [lock]. A search for newer Nix dev-env tools created since 2025-06 found
nothing credible above 200 stars [gh-meta].

---

## 4. Python: the options on merit

### 4.1 Facts that decide it

- **uv's interpreter selection.**
  - `UV_PYTHON` works like `--python`; a path pins one interpreter [uv-env#L104-107].
  - `UV_PYTHON_DOWNLOADS` controls downloads [uv-env#L241-245].
  - `UV_MANAGED_PYTHON` means "only uv-managed Pythons", i.e. never a system one
    [uv-env#L233-235] [uv-pyver#L386-422].
  - Discovery checks managed installs, then `PATH`. With the default preference, a matching
    system Python beats a download [uv-pyver#L294-319] [uv-pyver#L406-422].
- **Interpreter changes rebuild the venv.** In both variants, changing the interpreter made the
  next `uv sync` recreate `.venv` with no prompt. Tested for a minor bump (3.13→3.14) and a patch
  change (nixpkgs pin moved, 3.13.16→3.13.15) [local]. The "venv points at a dead store path"
  problem is handled.
- **Size and contents on darwin** [local]:

  |                               | nixpkgs `python313` (unstable)                        | uv-managed (python-build-standalone) |
  | ----------------------------- | ----------------------------------------------------- | ------------------------------------ |
  | Version on 2026-10-30         | 3.13.16                                               | 3.13.17                              |
  | Disk                          | 1.3 GiB closure (llvm-lib 379 MiB, apple-sdk 328 MiB) | 24 MiB download, 69 MiB installed    |
  | tkinter                       | missing (`No module named '_tkinter'`)                | included (Tk 9.0)                    |
  | OpenSSL / SQLite              | 3.5.9 / 3.53.3                                        | 3.5.9 / 3.53.1                       |
  | numpy, pandas, pyarrow wheels | work                                                  | work                                 |
  | sdist C extension             | builds                                                | builds                               |

- **NixOS.** nix-ld serves only unpatched executables that use `/lib64`'s loader. A nixpkgs Python
  "will not pick up `NIX_LD_LIBRARY_PATH`", so wheels in its venv need `LD_LIBRARY_PATH`
  [nixld-readme#L162-178]. A python-build-standalone binary is exactly such an unpatched
  executable, and NixOS's nix-ld defaults include `stdenv.cc.cc` (libstdc++) and zlib
  [nixos-nix-ld#L49-64]. **Not run on Linux** (§13).
- **The nixpkgs manual** calls pip in a venv "not very idiomatic" but documents it with
  `venvShellHook` for pre-existing projects [nixpkgs-python#L1859-1921]. This is your current
  pattern.

### 4.2 The five options

- **(a) uv in a Nix shell.** Two sub-variants, both tested:
  - **(a1) uv's own Python** (`UV_MANAGED_PYTHON=1`). **Pick.**
  - **(a2) nixpkgs Python** (`UV_PYTHON=<store path>`, `UV_PYTHON_DOWNLOADS=never`). Runner-up,
    §4.3.
- **(b) uv2nix / pyproject.nix.** Nix builds the venv from `uv.lock`. Its dev template uses a
  Nix-built editable venv with `UV_NO_SYNC=1`, `UV_PYTHON` and downloads off [uv2nix-hello#L75-88].
  - **Fact:** it ships no overrides. Packages that `uv.lock` describes poorly need hand-written
    fixes, "the biggest source of maintainer burnout for poetry2nix" [uv2nix-faq#L1-25].
  - It needs three more flake inputs [uv2nix-hello#L4-23].
  - **Assessment:** worth it to _ship_ a Python app as a Nix package or NixOS service, not for a
    dev loop. Trigger: a project you deploy to typhon with Nix.
- **(c) `python3.withPackages`.** Dependencies come from nixpkgs versions, not from your
  `pyproject.toml`. Collaborators and CI without Nix cannot reproduce it. Torch, catboost and
  pinned scikit-learn pickles (silcrst-team) need exact PyPI versions [local]. **Assessment: no,**
  except for small scripts.
- **(d) pixi.** It is conda-based, with a lockfile and PyPI integration, and supports C++ and R
  [pixi#L30-43] [pixi#L248]. direnv has `layout pixi` [direnv-stdlib#L862].
  - **Assessment:** better than uv when the stack is conda-forge or RoboStack (ROS, GDAL, CUDA
    toolchains, compilers as packages). Keep it for those projects. For PyPI-only projects it adds
    a second ecosystem.
- **(e) devenv `languages.python` with `uv.sync`.** It is the same idea as (a2) plus the
  `libraries` wrapper [devenv-py-docs#L140-160] [devenv-py#L342-350]. **Assessment:** take it when
  you take devenv for services ([dev-env.md §4.4](dev-env.md)), not for Python alone.

### 4.3 Why (a1) over (a2), and when (a2) wins

- **(a1) wins on:**
  - The interpreter is the same build as in CI and for collaborators.
  - It is about 10× smaller on darwin, includes tkinter, and gets patch releases earlier.
  - Linux wheels on typhon run through nix-ld with no per-project setup.
  - The flake is shorter: no `.python-version` parsing, no `PYTHONPATH` fix.
- **(a2) wins on:**
  - The interpreter is pinned by hash in `flake.lock`, and nothing is downloaded from GitHub
    (python-build-standalone releases).
  - Python then links against Nix-provided C libraries, and you may later mix in Nix-built
    Python packages.
- **Switch a project to (a2) when** it must work offline or air-gapped, links Nix C libraries
  (e.g. `libpq` from nixpkgs for psycopg built from source), or moves to uv2nix later. The tested
  file is in §9.4.
- **Patch pinning:** `.python-version` holds the minor version (`3.13`); uv picks the newest patch
  it knows [uv-pyver#L154-172]. Write `3.13.17` for an exact patch, at the cost of manual bumps.
  **Fact:** venvs point at a minor-version directory, a symlink to the current patch, so
  `uv python upgrade` does not break them [uv-pyver#L198-210] [local].

### 4.4 typhon (short)

- (a1) depends on `programs.nix-ld.enable` (already in `nix-ld.nix`).
- sdist builds need a compiler there: switch to `mkShell` or add `pkgs.gcc`.
- The `nix-ld.nix` comment ("pip wheels") is true for uv's Python and false for venvs on a
  nixpkgs Python [nixld-readme#L162-178].

---

## 5. direnv for Python: the `.envrc`

General nix-direnv behaviour (caching, GC roots, what invalidates the cache) is in
[dev-env.md §6](dev-env.md).

- **Fact:** direnv's `layout uv` (watch `.python-version pyproject.toml uv.lock`,
  `uv sync --frozen`, export `VIRTUAL_ENV`, add `.venv/bin` to PATH) first shipped in direnv v2.38.0
  [direnv-stdlib#L1144-1171] [gh-meta]. helios runs 2.37.1 [lock].
- **Fact:** `--frozen` installs from a stale `uv.lock` without saying so. Tested: after adding
  `six` to `pyproject.toml` by hand, `import six` failed and there was no warning. `--locked` fails
  loudly instead [uv-env#L388-396] [local].
- **So the `.envrc` (§9.1):**
  - `use flake`, then the `layout uv` steps written out with `--locked --quiet`.
  - Gate them on `uv.lock`, so the moment between `uv init` and `uv add` prints nothing.
  - Then `dotenv_if_exists`. Keep it as an explicit block even after direnv 2.38: `layout uv`
    hard-codes `--frozen` [direnv-stdlib#L1162].
  - Watch `.python-version`, `pyproject.toml` and `uv.lock` _after_ `use flake`. They then trigger
    `uv sync` but no Nix re-evaluation (tested).

---

## 6. Formatter, type checker, LSP, VS Code, hooks

- **ruff for format and lint.** It is one binary, in the uv `dev` group. **Fact:** the VS Code
  extension's `ruff.importStrategy` defaults to `fromEnvironment`: ruff from the selected
  environment, falling back to the bundled one [ruff-vscode].
- **Type checker: basedpyright.**
  - **Fact:** it is a pyright fork published on PyPI with node bundled via `nodejs-wheel-binaries`
    [bp-pyproject#L20-24].
  - **Fact:** its VS Code extension disables Pylance automatically and by default uses the
    basedpyright installed in the project (`basedpyright.importStrategy: fromEnvironment`); the
    default mode is `recommended` [bp-ides] [bp-vscode]. Editor diagnostics and CI then come from
    the same version and the same `[tool.basedpyright]`.
  - **ty:** "currently in beta", `0.0.x`, "breaking changes … may occur between any two
    versions" [ty-readme#L24] [ty-readme#L72-78]. Its Stable milestone has 98 open and 737 closed
    issues [gh-meta]. 26.05 ships 0.0.38 against 0.0.95 upstream [lock]. **Assessment:** switch
    when ty reaches stable; it is a one-line change in the dev group.
  - **mypy:** it is the reference checker with a plugin ecosystem (Django, Pydantic), and you use
    it strict in silcrst-team. **Assessment:** keep mypy where plugins or an existing mypy config
    matter. For new projects, basedpyright avoids the "Pylance says X, mypy says Y" split.
- **treefmt-nix per project: no.** ruff covers the Python. `nix fmt` with `nixfmt-tree` (treefmt
  preconfigured for nixfmt) covers `flake.nix` with no extra input [local].
- **How VS Code finds things:**
  - **Fact:** the Python Environments extension auto-selects a workspace `.venv` first
    [vsc-envs#L139-142] [vsc-envs#L417-423]. Its locator (PET 1.40.0, run directly) reported the
    test `.venv` as kind `Uv`, Python 3.13 [local]. No `python.defaultInterpreterPath` is needed.
  - **Fact:** `mkhl.direnv` loads the `.envrc` env into VS Code's integrated terminals and tasks
    [direnv-vscode#L1-30]. Its last release is v0.17.0 (2024-03) [gh-meta]. **Assessment:**
    optional, since Python tools come from `.venv`. Keep it so VS Code tasks see `uv` and `.env`.
- **pre-commit / git-hooks.nix: skip by default.** git-hooks.nix supports prek and has a
  flake-parts module [ghn#L16] [ghn#L163-165] [ghn#L309]. With format-on-save and the same checks
  in CI, hooks add a third place that runs them. Trigger: collaborators who push unformatted code.

---

## 7. CI

The general rule and runner costs are in [dev-env.md §7](dev-env.md).

- **Pick: `astral-sh/setup-uv` on `ubuntu-latest`, then `uv sync --locked` and `uv run …`**
  (§9.1).
  - **Fact:** setup-uv installs the `required-version` from `pyproject.toml`/`uv.toml`, or the
    latest uv [setup-uv#L26-36].
  - **Fact:** its cache defaults to `auto` [setup-uv-action#L38-40].
  - **Fact:** it sets `UV_PYTHON` only if you pass `python-version` [setup-uv#L148-153].
  - `UV_MANAGED_PYTHON: "1"` in the job makes CI ignore the runner's system Python, so CI and the
    dev shell use the same build.

---

## 8. What is pinned where

The `flake.lock` and CI-action rows are in [dev-env.md §8](dev-env.md).

| What                                                  | Pinned by                                               | Update with                                             |
| ----------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------- |
| Python minor (or patch)                               | `.python-version` (read by uv, setup-uv, collaborators) | edit the file                                           |
| Python patch (if minor only)                          | the uv version's download list                          | `nix flake update` locally; CI uses latest uv           |
| Every Python package incl. ruff, basedpyright, pytest | `uv.lock`                                               | `uv lock --upgrade` or `uv lock --upgrade-package ruff` |
| Tool config                                           | `pyproject.toml` `[tool.*]`                             | edit                                                    |

- After any of these, the next `cd` runs `uv sync --locked`. It rebuilds `.venv` if the
  interpreter changed (tested), and it is a no-op otherwise ("Checked 9 packages in 0.22ms")
  [local].
- **Fact:** a `uv.lock` written by uv 0.13.5 was read by uv 0.11.21 without complaint [local], so
  CI's newer uv and your shell's uv can differ.

---

## 9. The worked template

### 9.1 Files

`modules/flake/templates.nix`:

````nix
# Project templates: `nix flake init -t ~/nix-config#python`. The files live in
# ../../templates, outside modules/, so import-tree never imports them. All
# templates go in this one file: `flake.templates` has no merging option, so a
# second definition elsewhere is an error.
{
  flake.templates.python = {
    path = ../../templates/python;
    description = "Python project: Nix supplies uv, uv supplies Python and the dependencies";
    welcomeText = ''
      # Python project

      Next steps:

      ```sh
      direnv allow         # loads uv from flake.nix
      uv init --app        # or --lib; writes pyproject.toml
      uv add --dev ruff basedpyright pytest
      ```

      `.python-version` sets the Python version for uv here and in CI.
    '';
  };
}
````

`templates/python/flake.nix`:

```nix
{
  description = "Python dev shell: Nix supplies uv, uv supplies Python and the dependencies";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems =
        f: lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = [ pkgs.uv ];
          # uv installs the Python that .python-version names, the same
          # build setup-uv uses in CI; it never picks up a system Python.
          env.UV_MANAGED_PYTHON = "1";
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
```

`templates/python/.envrc`:

```bash
use flake

# uv owns Python and .venv (.python-version, pyproject.toml, uv.lock).
# Like direnv 2.38's `layout uv`, but --locked: a stale uv.lock is an
# error, not silently ignored.
watch_file .python-version pyproject.toml uv.lock
if [[ -f uv.lock ]]; then
  uv sync --locked --quiet
  export VIRTUAL_ENV="$PWD/.venv"
  PATH_add .venv/bin
fi

# Secrets go in .env (gitignored), never in this file.
dotenv_if_exists
```

`templates/python/.python-version`:

```text
3.13
```

`templates/python/.gitignore` (there is no global ignore, so this is the whole list):

```gitignore
.DS_Store
.direnv/
.venv/
.env
__pycache__/
.pytest_cache/
.ruff_cache/
result
```

`templates/python/.vscode/settings.json`:

```json
{
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true
  }
}
```

`templates/python/.vscode/extensions.json`:

```json
{
  "recommendations": [
    "ms-python.python",
    "charliermarsh.ruff",
    "detachhead.basedpyright",
    "mkhl.direnv"
  ]
}
```

`templates/python/.github/workflows/ci.yml` (passes `actionlint` 1.7.12; not run on GitHub):

```yaml
name: ci

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

jobs:
  check:
    runs-on: ubuntu-latest
    env:
      # Same Python build as the dev shell; never the runner's system Python.
      UV_MANAGED_PYTHON: "1"
    steps:
      - uses: actions/checkout@v7.0.1
      # Reads .python-version and uv.lock, the pins the dev shell uses too.
      - uses: astral-sh/setup-uv@v10.3.3
      - run: uv sync --locked
      - run: uv run ruff format --check
      - run: uv run ruff check
      - run: uv run basedpyright
      - run: uv run pytest
```

`pyproject.toml` comes from `uv init`, not the template, because init cannot substitute the
project name ([dev-env.md §4.1](dev-env.md)). `uv add --dev` writes the `dev` group. This optional snippet was tested and
passed `ruff check` and `basedpyright` on the test project:

```toml
[dependency-groups]          # written by `uv add --dev ruff basedpyright pytest`
dev = ["basedpyright>=1.40.2", "pytest>=9.2.0", "ruff>=0.17.3"]

[tool.ruff.lint]
extend-select = ["I", "UP", "B"]   # isort, pyupgrade, bugbear on top of the defaults

[tool.basedpyright]
typeCheckingMode = "recommended"   # the default; "standard" is gentler
```

### 9.2 Adding it to nix-config

```sh
cd ~/nix-config
# create the files above
git add modules/flake/templates.nix templates/python
nix flake check                           # prints "checking template 'templates.python'"
nix flake show | grep -A1 templates
```

Verified on a copy of the repo at `70c1710` [local]:

- `nix flake check --no-build` passed, including "checking template 'templates.python'".
- `nix fmt` changed nothing.

### 9.3 Creating a project

```sh
mkdir ~/Documents/projects/foo && cd ~/Documents/projects/foo
git init                                    # first: init stages its files only inside a repo
nix flake init -t ~/nix-config#python       # or -t github:Ety0011/nix-config#python once pushed
direnv allow
uv init --app                               # --lib for a library; keeps the template's .gitignore
uv add --dev ruff basedpyright pytest
uv add <your dependencies>
git add -A && git commit -m "chore: project skeleton"
```

- Every line was run in the scratchpad, using `direnv exec . <cmd>` in place of the interactive
  hook [local].
- The `github:` form needs nix-config pushed with the template (the repo is public [gh-meta]). It
  is not tested.
- **Why `git init` first** (tested): with `nix flake new` into a directory without git, `uv init`
  then created the repo. The flake files stayed untracked and the next load failed: "Path
  'flake.nix' … is not tracked by Git", followed by nix-direnv's fallback [local].
- `uv init --app` in uv 0.13.5 produced a `src/<name>/` package with `[project.scripts]` and the
  `uv_build` backend [local].

### 9.4 Runner-up flake (nixpkgs Python), tested

Use this when §4.3's conditions hold. Make the `.envrc` start with `watch_file .python-version`,
_before_ `use flake`, because this flake reads that file.

```nix
{
  description = "Python dev shell: Nix supplies Python and uv, uv owns the dependencies";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems =
        f: lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system: f nixpkgs.legacyPackages.${system});
      # One source of truth for the Python minor version: uv, setup-uv and this
      # flake all read .python-version ("3.13" -> pkgs.python313).
      pythonAttr =
        "python"
        + lib.replaceStrings [ "." ] [ "" ] (
          lib.versions.majorMinor (lib.trim (builtins.readFile ./.python-version))
        );
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          python = pkgs.${pythonAttr};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              python
              pkgs.uv
            ];
            env = {
              # uv uses exactly this interpreter and never downloads its own.
              UV_PYTHON = python.interpreter;
              UV_PYTHON_DOWNLOADS = "never";
            };
            # Python's setup hook points PYTHONPATH at the Nix site-packages,
            # which would leak into .venv.
            shellHook = "unset PYTHONPATH";
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
```

- **Fact:** without the `shellHook`, `PYTHONPATH` was set to the Nix Python's `site-packages`
  inside the shell [local].
- **Fact:** the shell also sets `SOURCE_DATE_EPOCH=315532800` (1980); this did not affect uv
  [local].
- On typhon this variant also needs
  `env.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];` for wheels that
  link libstdc++ [nixld-readme#L162-178]. Not tested.

### 9.5 Existing projects (optional; not run on the real projects)

- The five dev-templates projects work as they are. Migrate one when you next touch it:

  ```sh
  cd <project>
  git mv flake.nix flake.nix.old            # init refuses to overwrite; delete after
  mv .envrc .envrc.old                       # move its export lines into .env as KEY=value
  rm -rf .venv
  nix flake init -t ~/nix-config#python
  direnv allow
  uv lock                                     # from the existing pyproject.toml
  uv add -r requirements.txt                  # only where deps live in requirements.txt
  ```

- In `silcrst-team`, `dev` and `torch` are _extras_, which `uv sync` does not install by default.
  Either move `dev` to `[dependency-groups]` or use `uv sync --locked --all-extras` in `.envrc`.
  It is a shared repo, so agree the files (`flake.nix`, `.envrc`, `uv.lock`) with the other
  authors first.

---

## 10. What was tested (helios, aarch64-darwin, Nix 2.34.9, direnv 2.37.1)

All runs were in the scratchpad, with uv's Python and cache dirs redirected there
(`UV_PYTHON_INSTALL_DIR`, `UV_CACHE_DIR`) [local]. The global git ignores were still in place for
these runs.

| Command                                                                                                                               | Outcome                                                                                          |
| ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `uv init --app`; `uv add --dev ruff basedpyright pytest`                                                                              | uv.lock created; uv-managed CPython 3.13.17 downloaded (24.1 MiB)                                |
| `ruff format --check`, `ruff check`, `basedpyright`, `pytest -q` via direnv env                                                       | all pass (basedpyright `recommended`: 0 errors)                                                  |
| `python -c "import tkinter"`                                                                                                          | ok (Tk 9.0)                                                                                      |
| `.python-version` 3.13 → 3.14, reload                                                                                                 | venv rebuilt on 3.14.9 automatically                                                             |
| hand-edited `pyproject.toml`, `uv sync --locked`                                                                                      | error "lockfile … needs to be updated"; env still loads                                          |
| same with `--frozen`                                                                                                                  | no error; the new dependency silently missing                                                    |
| `uv run --with numpy --with pandas --with pyarrow …`                                                                                  | wheels import fine                                                                               |
| `uv run --no-binary-package markupsafe …`                                                                                             | sdist C extension builds with `/usr/bin/cc`                                                      |
| fresh clone, `env -i … uv sync --locked && uv run {ruff,basedpyright,pytest}` with `UV_MANAGED_PYTHON=1` (setup-uv emulation, no Nix) | all pass, same 3.13.17 / 3.14.9                                                                  |
| `nix develop -c sh -c 'uv run pytest -q'`                                                                                             | pass                                                                                             |
| `nix flake check` in the project                                                                                                      | all checks passed                                                                                |
| PET 1.40.0 `find -w -j` on the project                                                                                                | `.venv` found, kind `Uv`                                                                         |
| `actionlint ci.yml`                                                                                                                   | ok                                                                                               |
| runner-up (nixpkgs Python, §9.4): same flow                                                                                           | all pass; shell 1.4 GiB; venv rebuilt on 3.14 bump and on a nixpkgs pin change (3.13.16→3.13.15) |

Template-mechanics runs (init, flake check, direnv cache, `git init` order): [dev-env.md §9](dev-env.md).

---

## 11. When the runner-ups win

- **nixpkgs-Python variant (§9.4):** offline or air-gapped work, Python built against Nix C
  libraries, or a later move to uv2nix.
- **pixi:** conda-forge or RoboStack stacks (your ROS project), or CUDA or GDAL with
  conda-provided compilers.
- **uv2nix:** you want to ship the app as a Nix package or NixOS service on typhon.

---

## 12. Side findings

- **`nix-ld.nix` comment** ("pip wheels"): true for uv's Python, false for venvs on a nixpkgs
  Python [nixld-readme#L162-178]. Worth one clarifying word when typhon is installed.

---

## 13. Limitations (not verified)

- **Nothing ran on Linux.** On typhon and ubuntu, these rest on docs only:
  - python-build-standalone through nix-ld;
  - basedpyright's bundled node and ruff wheels;
  - sdist builds without a compiler;
  - the runner-up's `LD_LIBRARY_PATH` line.
- **The CI workflow was not run on GitHub.** It passes actionlint, and its steps were emulated
  locally with uv 0.13.5 on darwin. setup-uv's own behaviour (latest uv, cache) is from its docs.
- **VS Code was not opened.** `.venv` discovery was checked with the extension's PET binary. That
  the ruff and basedpyright extensions pick up `.venv` binaries is from their settings defaults,
  and that basedpyright disables Pylance is from its docs.
- **Not run:**
- **Not run:**
  - the migration steps on real projects (§9.5);
  - Dependabot `uv` updates;
  - uv2nix and pixi themselves.
- **Darwin-only sizes.** The 1.3 GiB Python closure is a darwin number; on Linux it is likely
  smaller.

---

## 14. Sources

Metadata and local: [gh-meta], [lock] and [local] as in [dev-env.md §14](dev-env.md).

direnv

- [nd-direnvrc] https://github.com/nix-community/nix-direnv/blob/babed5598d2594b71677ca18674d027bc4549eb0/direnvrc
  (L164-204, L208-218, L258-266, L277-408)
- [nd-readme] …/README.md (L5-16, L189-221, L300-326, L346-358)
- [direnv-stdlib] https://github.com/direnv/direnv/blob/3d0b4ae1ed83064a10ada052949596e7463a8768/stdlib.sh
  (L862, L1144-1171)
- [direnv-vscode] https://github.com/direnv/direnv-vscode/blob/8fd4f14686b4736c67a6102a5263731a42cfc732/README.md (L1-30)

Python

- [uv-env] https://github.com/astral-sh/uv/blob/55de8184f4a5f6535cd93798128d40e8d042647f/crates/uv-static/src/env_vars.rs
  (L104-107, L233-245, L383-396, L475-480)
- [uv-pyver] …/docs/concepts/python-versions.md (L61-74, L154-172, L198-210, L294-319, L372-422)
- [uv2nix-hello] https://github.com/pyproject-nix/uv2nix/blob/c361746c7d630d98b972378290547c8d35542a7a/templates/hello-world/flake.nix
  (L4-23, L75-88) · [uv2nix-faq] …/doc/src/FAQ.md (L1-25)
- [nixpkgs-python] https://github.com/NixOS/nixpkgs/blob/d592aacecd3575d7e11de963d9b20dd2ef4db603/doc/languages-frameworks/python.section.md
  (L1859-1921)
- [nixld-readme] https://github.com/nix-community/nix-ld/blob/af1a6c38d6a9889f7acfd14cece8ea1834ee8035/README.md (L30-38, L152-178)
- [nixos-nix-ld] https://github.com/NixOS/nixpkgs/blob/1f607aa79b6356ed45d3cd3c8079c196e79efa2c/nixos/modules/programs/nix-ld.nix (L44-64)
- [dt-python] https://github.com/the-nix-way/dev-templates/blob/9ffac48bbda3ba44e58e250d9a57d4520ce55401/python/flake.nix (L1-101)
- [pixi] https://github.com/prefix-dev/pixi/blob/f1fab35b21c697b04933289320eddeb67641cb67/README.md (L30-43, L248)

Alternatives

- [devenv-readme] https://github.com/cachix/devenv/blob/0d6c556e5f862c14a75a543e2ee4fdb7acc005ad/README.md (L24-60, L131-156)
- [devenv-py] …/src/modules/languages/python/default.nix (L10-12, L342-350, L412-433, L500)
- [devenv-py-docs] …/docs/src/content/docs/languages/python.md (L14-64, L134-184, L256-261)
- [devenv-flakes] …/docs/src/content/docs/guides/using-with-flakes.md (L17-33)

Formatter, checker, editor

- [ruff-vscode] https://github.com/astral-sh/ruff-vscode/blob/073e088670dffbad0039f61f2d71af0257cfe7f4/package.json
  (`ruff.importStrategy`, `ruff.interpreter`)
- [bp-pyproject] https://github.com/DetachHead/basedpyright/blob/82c89848dbd400920ad4a2ca7c148a9b1644e086/pyproject.toml (L20-24)
- [bp-ides] …/docs/installation/ides.md (L9-30) · [bp-vscode] …/packages/vscode-pyright/package.json
  (`basedpyright.importStrategy`, `basedpyright.analysis.typeCheckingMode`)
- [ty-readme] https://github.com/astral-sh/ty/blob/48c5ea1baf6144dc9918ae60040aaa4198b251ce/README.md (L24, L72-78) ·
  …/docs/modules.md (L55-65) · …/docs/editors.md (L8-29)
- [vsc-envs] https://github.com/microsoft/vscode-docs/blob/af4859a5fb06e699ca687d0bd56367f5ed0f3399/docs/python/environments.md
  (L38-49, L139-142, L417-423)
- [ghn] https://github.com/cachix/git-hooks.nix/blob/1ba1dbfe28738c9a71c266be6efa5b89e75491a9/README.md (L16, L163-165, L309)

CI

- [setup-uv] https://github.com/astral-sh/setup-uv/blob/4c58170a945e4e68ce3fc5b7af3d341d9b8c64ef/README.md (L26-36, L148-153) ·
  [setup-uv-action] …/action.yml (L6-14, L38-40)
