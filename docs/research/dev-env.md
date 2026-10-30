# Per-project dev environments: pattern and a Python template

Research date: 2026-10-30. Method: each candidate's own repo or docs were read at the commits in §17,
and claims were followed to the code that owns them (Nix's `flake init`/`flake check`, flake-parts,
import-tree, nix-direnv, direnv's stdlib, uv, devenv, uv2nix, nix-ld, basedpyright, ty, the VS Code
extensions, GitHub's docs). Package versions come from this flake's locked inputs [lock]. The
recommended template was built in a throwaway copy of this repo and tested end to end on helios in
the scratchpad (§12). Nothing in the config or in your projects was changed [local]. Stars and push
dates come from `gh api repos/<owner>/<repo>` on 2026-10-30 [gh-meta]. "Fact" statements carry a
citation; **Assessment** marks my judgement. Familiarity was not used as a reason for any pick.

---

## 1. TL;DR

- **Pattern: a flake `templates` output in nix-config. Each project gets its own small, plain
  `flake.nix` plus `.envrc`.** Nix supplies the tools (here only `uv`). **uv supplies Python and
  every Python dependency**, from `.python-version`, `pyproject.toml` and `uv.lock`. direnv with
  nix-direnv activates the shell and the `.venv` when you `cd` in.
- **The Python interpreter comes from uv (python-build-standalone), not from nixpkgs.** This
  reverses the obvious Nix choice, and I tested both (§7). Reasons, all on merit:
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
- **CI: `setup-uv` on `ubuntu-latest`, no Nix.** The dev shell only provides `uv`, and setup-uv
  provides that too. Nix in CI would add an install step and test nothing extra (§9). Skip macOS
  runners: they cost about 10× more per minute [gh-prices].
- **Where it goes:** `modules/flake/templates.nix` (one file for all templates) plus
  `templates/python/` at the repo root, outside `modules/`, so import-tree never sees it (§4.2).
- **Gotcha found:** run `git init` before `nix flake init`. Otherwise `uv init` creates the repo
  later, the flake files are untracked, and evaluation fails (tested). A second gotcha, the
  global `.envrc` ignore hiding `templates/python/.envrc`, is gone: the global ignores were
  removed from `git.nix` after this research (§15).
- **Runner-ups:** the nixpkgs-Python variant (§7.3, tested, full file in §11.4); devenv when a
  project needs services; pixi for conda-forge or ROS stacks, as you already do for robotics.
  The old `c`/`python` devShells are already gone (`9f2a720`). **No ADR**: each project can undo
  this on its own (§14).

---

## 2. How you work today (evidence)

All read-only on 2026-10-30 [local]; secret values in `.envrc` files were not read.

- **Five Python projects use the-nix-way/dev-templates `python` template verbatim:** pip plus
  `venvShellHook`, nixpkgs from FlakeHub's rolling `0.1`, Python 3.13 [dt-python#L4]
  [dt-python#L59-94]. They are `silcrst-team`, `spotify_to_ytmusic`, `whiteboard-transcriber-main`,
  `engineering-AI-systems` and `natural-language-processing`. History has
  `nix flake init --template github:the-nix-way/dev-templates#python` [local].
- **No Python lockfile anywhere.** There is no `uv.lock`, and dependencies come from
  `pip install -r requirements.txt` or `pip install .` (203 `pip install` lines in history, 0 `uv`
  lines) [local]. Each `.venv` points into `/nix/store/…-python3-3.13.x` [local].
- **pixi is used heavily (314 history lines) for one ROS 2 project:** RoboStack channels, `compilers`,
  `boost` and conda packages, plus a Nix flake for LaTeX that runs `pixi shell-hook` [local].
- **One team repo has non-Nix collaborators:** `silcrst-team` is `vivo0/silcrst-team`, and its
  `pyproject.toml` mentions another author's branch. It uses mypy strict and has extras
  `dev = [pytest, mypy]` and `torch` [local].
- **Secrets live in `.envrc`:** `engineering-AI-systems/.envrc` exports two tokens [local]. This
  was why `.envrc` was globally git-ignored; that list has since been removed from `git.nix`, and
  the repo's own `.gitignore` covers its `.envrc`.
- **VS Code has** `ms-python.python`, Pylance, `ms-python.vscode-python-envs`,
  `charliermarsh.ruff` and `mkhl.direnv` installed [local].
- **Already gone:** the `c`/`python` devShells in nix-config were dropped in `9f2a720`
  ("never used") [local].

---

## 3. Candidates and activity

| Candidate                        | Stars | Last push  | Latest                                         | Role                           |
| -------------------------------- | ----- | ---------- | ---------------------------------------------- | ------------------------------ |
| flake `templates` (Nix built-in) | n/a   | n/a        | Nix 2.34.9 local                               | delivery                       |
| hercules-ci/flake-parts          | 1.5k  | 2026-10-01 | locked `024633c`                               | `flake.templates` in this repo |
| nix-community/nix-direnv         | 2.8k  | 2026-10-25 | 3.2.0 (26.05 has 3.1.2)                        | cached `use flake`             |
| direnv/direnv                    | 15.5k | 2026-10-26 | 2.38.2 (26.05 has 2.37.1)                      | `.envrc`                       |
| astral-sh/uv                     | 91k   | 2026-10-30 | 0.13.6 (unstable 0.13.4/0.13.5, 26.05 0.11.21) | Python and dependencies        |
| cachix/devenv                    | 7.8k  | 2026-10-30 | v2.4.0 (26.05 has 2.1.2)                       | alternative                    |
| numtide/devshell                 | 1.6k  | 2026-10-15 | n/a                                            | alternative                    |
| flox/flox                        | 4.2k  | 2026-10-30 | v1.19.3                                        | alternative                    |
| jetify-com/devbox                | 12.4k | 2026-10-29 | 0.19.0                                         | alternative                    |
| the-nix-way/dev-templates        | 2.4k  | 2026-10-13 | n/a                                            | your current source            |
| pyproject-nix/uv2nix             | 790   | 2026-10-29 | no releases                                    | alternative (Nix-built venv)   |
| prefix-dev/pixi                  | 7.9k  | 2026-10-30 | v0.83.0 (26.05 has 0.68.1)                     | alternative (conda)            |
| astral-sh/ruff                   | 50k   | 2026-10-30 | 0.17.3                                         | format and lint                |
| DetachHead/basedpyright          | 3.6k  | 2026-10-28 | v1.40.2                                        | type checker                   |
| astral-sh/ty                     | 20k   | 2026-10-29 | 0.0.95 (beta)                                  | type checker (later)           |
| cachix/git-hooks.nix             | 877   | 2026-10-26 | n/a                                            | hooks (skipped)                |
| astral-sh/setup-uv               | 898   | 2026-10-28 | v10.3.3                                        | CI                             |
| cachix/install-nix-action        | 708   | 2026-10-27 | v31.11.3                                       | CI (alternative)               |

Sources: [gh-meta] [lock]. A search for newer Nix dev-env tools created since 2025-06 found
nothing credible above 200 stars [gh-meta].

---

## 4. Delivery: templates vs the alternatives

### 4.1 How `nix flake init -t` works

- **Fact:** a template has `path`, `description` and optionally `welcomeText` (Markdown shown after
  init) [nix-flake-init#L30-41]. `nix flake check` rejects any other attribute [nix-flake.cc#L546-575].
- **Fact:** init copies the files verbatim. Nothing is substituted, so the project name cannot be
  templated. It never overwrites an existing file: a differing file is reported as a conflict and
  the command fails at the end [nix-flake.cc#L937-1006].
- **Fact:** if the target directory has `.git`, the written files are staged with
  `git add --intent-to-add --force`. They are tracked even if an ignore rule matches them
  [nix-flake.cc#L985-995] [local].
- **Fact:** `nix flake check` only checks that a template's `path` exists ("TODO: recursively check
  the flake in 'path'") [nix-flake.cc#L556-558]. The template's own `flake.nix` is never evaluated
  by nix-config's check, so §12 tests it separately.
- **Fact:** `nix flake new -t … <dir>` does the same into a new directory without `git init`
  [local]. **Assessment:** use `git init && nix flake init`; §11.2 shows why.

### 4.2 Where it goes in this repo

- **Fact:** `flake` in flake-parts is a freeform `lazyAttrsOf (unique raw)`. An output without a
  declared option, like `templates`, must be defined once, in a single module
  [fp-flake.nix#L10-31]. Tested: a second file setting `flake.templates.c` fails with "The option
  `flake.templates' is defined multiple times while it's expected to be unique" [local].
- **Fact:** import-tree imports only `*.nix` paths without `/_` under the directory it is given
  [import-tree#L64]. This repo gives it `./modules` (`flake.nix`).
- **So:**
  - `modules/flake/templates.nix`: one module, all templates. It is a flake-level output, like
    `formatter.nix`, not a Feature, so Roles are not involved. "Import each module along exactly
    one path" holds trivially.
  - `templates/python/…`: data files at the repo root. They are outside `./modules`, so they are
    never imported.
  - treefmt still formats them. nix-config's nixfmt and the project's `nixfmt-tree` produced
    identical output for `flake.nix`, and the JSON/YAML files came through unchanged [local].
- **Fact:** a path flake ref to a git repo sees tracked files only. While the global ignore
  listed `.envrc`, `git add templates/python` skipped it, and `nix flake init` then wrote every
  file except `.envrc` without any warning (tested) [local]. With the global ignores removed, a
  plain `git add templates/python` tracks it. If a template file is ever missing from
  `nix flake init`, check `git ls-files templates/` first.

### 4.3 devShells kept in nix-config (`use flake ~/nix-config#python`)

- **Fact:** nix-direnv accepts an external flake ref [nd-readme#L213-221], so this works
  mechanically.
- **Assessment: no.** The project then depends on a path that exists only on your machines. CI and
  collaborators cannot use it, and a nix-config lock bump changes every project at once. You
  already removed these shells for being unused (`9f2a720`).

### 4.4 devenv

- **Fact:** devenv 2.x has its own CLI, `devenv.nix`, `devenv.yaml` and `devenv.lock`, 40+
  services, a process manager, git-hooks integration and `devenv test` [devenv-readme#L24-60]
  [devenv-readme#L131-156]. It recommends its CLI over flake integration ("performance
  limitations and reduced features") [devenv-flakes#L17-33].
- **Fact:** its Python module can run `uv sync` on entry and pins uv to its own interpreter
  [devenv-py-docs#L140-160]. It also wraps the interpreter with `LD_LIBRARY_PATH` /
  `DYLD_FALLBACK_LIBRARY_PATH` built from `languages.python.libraries`, with an optional
  `manylinux2014` set [devenv-py#L10-12] [devenv-py#L342-350] [devenv-py#L412-433].
- **Assessment:** it would be a second tool and a second lock format for what a 20-line flake does.
  It wins when a project needs **services or processes** (PostgreSQL, Redis, a worker). This
  confirms best-of-nix §4.5.

### 4.5 devshell, flox, devbox, dev-templates

- **devshell:** README says "STATUS: unstable" [devshell#L3]. It replaces `mkShell` with a TOML or
  module layer and a command menu, which adds nothing for one tool.
- **flox / devbox:** both are Nix underneath with their own manifest and lock, aimed at teams that
  should not need to learn Nix [flox#L42] [flox#L90] [devbox#L27-31] [devbox#L57]. You are using
  Nix directly, so they add a layer without a gain.
- **the-nix-way/dev-templates `python`:** pip plus `venvShellHook`, with no lockfile and nixpkgs
  from FlakeHub [dt-python#L4] [dt-python#L59-94].
  - **Assessment:** a good catalogue of starting points for other languages, but its Python
    template leaves dependencies unpinned.
  - The venv points at a Nix store Python that the template does not rebuild when nixpkgs moves.
    It only prints a warning [dt-python#L62-76].

---

## 5. The project flake

- **Plain flake, not flake-parts.** It has one input and one output per system. flake-parts would
  add an input and a framework to a 20-line file. **Assessment:** flake-parts earns its place in
  nix-config (many modules), not here.
- **nixpkgs branch: `nixpkgs-unstable`, the project's own lock.**
  - **Fact:** `nixpkgs-unstable` advances only after the `nixpkgs/unstable/unstable` Hydra job,
    whose constituents include `aarch64-darwin` builds such as `stdenv` and `python3`
    [channels.nix#L37-40] [release.nix#L164-212].
  - **Fact:** `nixos-unstable` gates on `nixos/unstable/tested` instead [channels.nix#L27-31].
  - **Fact:** for the one tool the shell carries, 26.05 has uv 0.11.21 and unstable has 0.13.x
    [lock].
  - **Assessment:** use `nixpkgs-unstable`. The newest uv matters, the branch is checked on darwin,
    and nothing else in the shell can break.
- **Do not follow the system's nixpkgs.** An `inputs.nixpkgs.url = "nixpkgs"` would resolve
  through your registry, which nix-config pins to `nixpkgs-26.05-darwin` on helios and
  `nixos-26.05` on typhon (`modules/features/nixpkgs.nix` L15, L20). `nix flake update` would then
  give different answers per host. A `nix-config` input would tie every project to this repo.
- **Systems:** `aarch64-darwin` and `x86_64-linux`, your two Hosts and `ubuntu-latest`. Add
  `aarch64-linux` only if a project needs it.
- **`mkShellNoCC`:** Python comes from uv, so the shell needs no compiler. An sdist C extension
  (markupsafe built with `--no-binary-package`) compiled fine with Xcode's `/usr/bin/cc`.
  `sysconfig` `CC` is `cc` [local]. On typhon there is no system compiler; see §7.4.
- **Update cadence:** `nix flake update` when you want a newer uv, or monthly. The lock only moves
  `uv` and `nixfmt-tree`, so this is low risk.

---

## 6. direnv and nix-direnv

- **Fact:** nix-direnv's `use flake` caches `nix print-dev-env` output in `.direnv/` and roots the
  shell and all flake inputs as GC roots (`nix build --out-link`). When evaluation fails it falls
  back to the last good shell [nd-direnvrc#L208-212] [nd-direnvrc#L347-399]. Your `nix.gc`
  (`--delete-older-than 7d`) deletes old profile generations only, and `programs.nh.clean` is off
  (`nix-tools.nix` L5), so these roots survive. `nh clean` would need `--no-direnv`
  [nd-readme#L348-358].
- **Fact:** the cache is invalidated only when `~/.direnvrc`, `.envrc`, `flake.nix`, `flake.lock`,
  `devshell.toml` or a file watched _before_ `use flake` is newer than the cache
  [nd-direnvrc#L298-304] [nd-direnvrc#L318-341] [nd-readme#L300-326]. Tested: `touch uv.lock`
  printed "Using cached dev shell", and a reload with a warm cache took 0.1 s [local].
- **Fact:** direnv's `layout uv` (watch `.python-version pyproject.toml uv.lock`,
  `uv sync --frozen`, export `VIRTUAL_ENV`, add `.venv/bin` to PATH) first shipped in direnv v2.38.0
  [direnv-stdlib#L1144-1171] [gh-meta]. helios runs 2.37.1 [lock].
- **Fact:** `--frozen` installs from a stale `uv.lock` without saying so. Tested: after adding
  `six` to `pyproject.toml` by hand, `import six` failed and there was no warning. `--locked` fails
  loudly instead [uv-env#L388-396] [local].
- **Fact:** direnv carries on after a failing command in `.envrc`. With a stale lock the env still
  loaded and the uv error was printed [local].
- **So the `.envrc` (§11.1):**
  - `use flake`, then the `layout uv` steps written out with `--locked --quiet`.
  - Gate them on `uv.lock`, so the moment between `uv init` and `uv add` prints nothing.
  - Then `dotenv_if_exists`. Keep it as an explicit block even after direnv 2.38: `layout uv`
    hard-codes `--frozen` [direnv-stdlib#L1162].
  - Watch `.python-version`, `pyproject.toml` and `uv.lock` _after_ `use flake`. They then trigger
    `uv sync` but no Nix re-evaluation (tested).
- **Secrets:** move `export TOKEN=…` lines into `.env` (`KEY=value`, gitignored).
  `dotenv_if_exists` loads it. The committed `.envrc` then holds no secrets.

---

## 7. Python: the options on merit

### 7.1 Facts that decide it

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
  [nixos-nix-ld#L49-64]. **Not run on Linux** (§16).
- **The nixpkgs manual** calls pip in a venv "not very idiomatic" but documents it with
  `venvShellHook` for pre-existing projects [nixpkgs-python#L1859-1921]. This is your current
  pattern.

### 7.2 The five options

- **(a) uv in a Nix shell.** Two sub-variants, both tested:
  - **(a1) uv's own Python** (`UV_MANAGED_PYTHON=1`). **Pick.**
  - **(a2) nixpkgs Python** (`UV_PYTHON=<store path>`, `UV_PYTHON_DOWNLOADS=never`). Runner-up,
    §7.3.
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
  you take devenv for services (§4.4), not for Python alone.

### 7.3 Why (a1) over (a2), and when (a2) wins

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
  file is in §11.4.
- **Patch pinning:** `.python-version` holds the minor version (`3.13`); uv picks the newest patch
  it knows [uv-pyver#L154-172]. Write `3.13.17` for an exact patch, at the cost of manual bumps.
  **Fact:** venvs point at a minor-version directory, a symlink to the current patch, so
  `uv python upgrade` does not break them [uv-pyver#L198-210] [local].

### 7.4 typhon (short)

- (a1) depends on `programs.nix-ld.enable` (already in `nix-ld.nix`).
- sdist builds need a compiler there: switch to `mkShell` or add `pkgs.gcc`.
- The `nix-ld.nix` comment ("pip wheels") is true for uv's Python and false for venvs on a
  nixpkgs Python [nixld-readme#L162-178].

---

## 8. Formatter, type checker, LSP, VS Code, hooks

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

## 9. CI

- **Pick: `astral-sh/setup-uv` on `ubuntu-latest`, then `uv sync --locked` and `uv run …`**
  (§11.1).
  - **Fact:** setup-uv installs the `required-version` from `pyproject.toml`/`uv.toml`, or the
    latest uv [setup-uv#L26-36].
  - **Fact:** its cache defaults to `auto` [setup-uv-action#L38-40].
  - **Fact:** it sets `UV_PYTHON` only if you pass `python-version` [setup-uv#L148-153].
  - `UV_MANAGED_PYTHON: "1"` in the job makes CI ignore the runner's system Python, so CI and the
    dev shell use the same build.
- **Why not `nix develop -c …` in CI:**
  - The shell holds only `uv`.
  - **Fact:** install-nix-action takes about 4 s on Linux and about 20 s on macOS
    [inix#L9]; fetching nixpkgs and the shell comes on top.
  - **Fact:** magic-nix-cache caches what the workflow _builds_ [mnc#L1-30]. Here nothing is
    built: the only local build was the trivial `nix-shell-env` derivation [local].
  - **Fact:** `nix flake check` only evaluates devShells; it builds `checks` for the current system
    [nix-flake.cc#L617-669].
- **Cost:**
  - **Fact:** per minute, Linux 2-core costs $0.006 and macOS $0.062 [gh-prices].
  - **Fact:** standard runners are free in public repos [gh-billing#L127-130].
  - **Assessment:** run Linux only. helios is your macOS test.
- **When Nix in CI wins:** the shell supplies non-Python tools the tests call (ffmpeg, a database
  client, texlive). Then `cachix/install-nix-action` plus `nix develop -c uv run pytest` on Ubuntu
  only. Verified locally on darwin: `nix develop -c sh -c 'uv run pytest'` passed [local].
- **Automated updates (optional, untested):**
  - **Fact:** Dependabot supports `uv` (version and security updates) [dbot#L58-61].
  - **Fact:** it supports `nix` (`flake.lock` inputs, public repos only) [dbot#L33-34]
    [dbot#L174-178].

---

## 10. What is pinned where, and how updates flow

| What                                                  | Pinned by                                               | Update with                                             |
| ----------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------- |
| uv binary, nixfmt-tree                                | `flake.lock` (nixpkgs-unstable rev)                     | `nix flake update`                                      |
| Python minor (or patch)                               | `.python-version` (read by uv, setup-uv, collaborators) | edit the file                                           |
| Python patch (if minor only)                          | the uv version's download list                          | `nix flake update` locally; CI uses latest uv           |
| Every Python package incl. ruff, basedpyright, pytest | `uv.lock`                                               | `uv lock --upgrade` or `uv lock --upgrade-package ruff` |
| Tool config                                           | `pyproject.toml` `[tool.*]`                             | edit                                                    |
| CI actions                                            | exact tags in `ci.yml`                                  | edit (or Dependabot `github-actions`)                   |

- After any of these, the next `cd` runs `uv sync --locked`. It rebuilds `.venv` if the
  interpreter changed (tested), and it is a no-op otherwise ("Checked 9 packages in 0.22ms")
  [local].
- **Fact:** a `uv.lock` written by uv 0.13.5 was read by uv 0.11.21 without complaint [local], so
  CI's newer uv and your shell's uv can differ.

---

## 11. The worked template

### 11.1 Files

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
project name (§4.1). `uv add --dev` writes the `dev` group. This optional snippet was tested and
passed `ruff check` and `basedpyright` on the test project:

```toml
[dependency-groups]          # written by `uv add --dev ruff basedpyright pytest`
dev = ["basedpyright>=1.40.2", "pytest>=9.2.0", "ruff>=0.17.3"]

[tool.ruff.lint]
extend-select = ["I", "UP", "B"]   # isort, pyupgrade, bugbear on top of the defaults

[tool.basedpyright]
typeCheckingMode = "recommended"   # the default; "standard" is gentler
```

### 11.2 Adding it to nix-config

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

### 11.3 Creating a project

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

### 11.4 Runner-up flake (nixpkgs Python), tested

Use this when §7.3's conditions hold. Make the `.envrc` start with `watch_file .python-version`,
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

### 11.5 Existing projects (optional; not run on the real projects)

- The five dev-templates projects work as they are. Migrate one when you next touch it:

  ```sh
  cd <project>
  git mv flake.nix flake.nix.old            # init refuses to overwrite (§4.1); delete after
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

## 12. What was tested (helios, aarch64-darwin, Nix 2.34.9, direnv 2.37.1)

All runs were in the scratchpad, with uv's Python and cache dirs redirected there
(`UV_PYTHON_INSTALL_DIR`, `UV_CACHE_DIR`) [local]. The global git ignores were still in place for
these runs.

| Command                                                                                                                               | Outcome                                                                                          |
| ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `git clone ~/nix-config` → copy; add `templates.nix` + `templates/python`; `git add`                                                  | `.envrc` silently missing (global ignore)                                                        |
| `nix flake init -t <copy>#python` before `git add -f .envrc`                                                                          | 6 files written, no `.envrc`, no warning                                                         |
| same after `git add -f templates/python/.envrc`                                                                                       | 7 files written and staged intent-to-add; welcomeText rendered                                   |
| second module defining `flake.templates.c`                                                                                            | error "defined multiple times while it's expected to be unique"                                  |
| `nix flake check --no-build` on the copy                                                                                              | "checking template 'templates.python'… all checks passed"                                        |
| `nix fmt` on the copy                                                                                                                 | 0 files changed                                                                                  |
| `direnv allow` + `direnv exec . …` (first load)                                                                                       | shell built; then "Using cached dev shell", 0.1 s                                                |
| `uv init --app`; `uv add --dev ruff basedpyright pytest`                                                                              | uv.lock created; uv-managed CPython 3.13.17 downloaded (24.1 MiB)                                |
| `ruff format --check`, `ruff check`, `basedpyright`, `pytest -q` via direnv env                                                       | all pass (basedpyright `recommended`: 0 errors)                                                  |
| `python -c "import tkinter"`                                                                                                          | ok (Tk 9.0)                                                                                      |
| `.python-version` 3.13 → 3.14, reload                                                                                                 | venv rebuilt on 3.14.9 automatically                                                             |
| `touch uv.lock`, reload                                                                                                               | "Using cached dev shell" (no Nix re-eval)                                                        |
| hand-edited `pyproject.toml`, `uv sync --locked`                                                                                      | error "lockfile … needs to be updated"; env still loads                                          |
| same with `--frozen`                                                                                                                  | no error; the new dependency silently missing                                                    |
| `uv run --with numpy --with pandas --with pyarrow …`                                                                                  | wheels import fine                                                                               |
| `uv run --no-binary-package markupsafe …`                                                                                             | sdist C extension builds with `/usr/bin/cc`                                                      |
| fresh clone, `env -i … uv sync --locked && uv run {ruff,basedpyright,pytest}` with `UV_MANAGED_PYTHON=1` (setup-uv emulation, no Nix) | all pass, same 3.13.17 / 3.14.9                                                                  |
| `nix develop -c sh -c 'uv run pytest -q'`                                                                                             | pass                                                                                             |
| `nix flake check` in the project                                                                                                      | all checks passed                                                                                |
| PET 1.40.0 `find -w -j` on the project                                                                                                | `.venv` found, kind `Uv`                                                                         |
| `actionlint ci.yml`                                                                                                                   | ok                                                                                               |
| `nix flake new` + `uv init` (no prior `git init`)                                                                                     | "Path 'flake.nix' … is not tracked by Git"                                                       |
| runner-up (nixpkgs Python, §11.4): same flow                                                                                          | all pass; shell 1.4 GiB; venv rebuilt on 3.14 bump and on a nixpkgs pin change (3.13.16→3.13.15) |

---

## 13. Review of earlier verdicts

| Where                          | Earlier verdict                                                                                               | Now                                                                                                                                                                                                                        |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| best-of-nix L25-26             | Keep nix-direnv and plain `mkShell` devShells                                                                 | **Confirmed**, refined: plain `mkShellNoCC` in each project's flake, not devShells in nix-config                                                                                                                           |
| best-of-nix L264-266           | devenv when a project needs services; per project; `mkShell` + nix-direnv stays default                       | **Confirmed** (devenv v2.4.0; it also handles NixOS native libs, §4.4)                                                                                                                                                     |
| best-of-nix L297-299           | Flake templates; dev-templates "a good source"                                                                | Templates **confirmed**; dev-templates as the Python source **overturned** (pip, no lock, §4.5)                                                                                                                            |
| best-of-nix L339               | devshell, devbox, flox skipped                                                                                | **Confirmed** with reasons (§4.5)                                                                                                                                                                                          |
| features.md L40, L364-366      | uv "when needed", via HM `programs.uv`, "manages its own Pythons, so no store-path venvs that break after gc" | **Partly overturned:** uv comes from each project's flake, not HM; no global uv needed. The gc concern is moot in both variants: nix-direnv roots the shell and uv rebuilds the venv when the interpreter changes (tested) |
| features.md L106 (§3.2)        | Keep `nix-direnv`; it roots devShells against gc                                                              | **Confirmed** from source [nd-direnvrc#L208-212] [nd-direnvrc#L357-377]                                                                                                                                                    |
| features.md L200, L274 (§3.15) | Remove `c`/`python` devShells or turn them into templates                                                     | **Confirmed**, and done in `9f2a720`. `python` is now a template; `c` waits for its trigger                                                                                                                                |
| features.md L362-364           | Trigger: next C or Python project; `nix flake init -t ~/nix-config#python`                                    | **Confirmed**, with one precondition: `git init` first (`git add -f` no longer needed)                                                                                                                                     |
| features.md L497               | "refactor: drop devShells (or templates)"                                                                     | Done (`9f2a720`)                                                                                                                                                                                                           |

---

## 14. When the runner-up wins, the `c` template, and the ADR question

- **nixpkgs-Python variant (§11.4):** offline or air-gapped work, Python built against Nix C
  libraries, or a later move to uv2nix.
- **devenv:** the project needs services or processes (PostgreSQL, Redis, workers), or several
  languages with managed native libraries on NixOS.
- **pixi:** conda-forge or RoboStack stacks (your ROS project), or CUDA or GDAL with
  conda-provided compilers.
- **uv2nix:** you want to ship the app as a Nix package or NixOS service on typhon.
- **Nix in CI:** the dev shell carries non-Python tools the tests run.
- **`c` template:** add `flake.templates.c` to the same `templates.nix` and a `templates/c/` when
  the next C/C++ project starts. That is `mkShell` (it needs a compiler), clang-tools, cmake and
  ninja, as in the deleted shell. Do not add it before then.
- **ADR: not warranted.** The bar is all three of: hard to reverse, surprising without context,
  and a real trade-off. This fails the first: each project owns its flake and can switch
  variants, or drop Nix, alone. The comment in `templates.nix` and this document cover the "why
  is Python not from Nix?" question. Revisit if many projects come to depend on a shared
  mechanism (e.g. a `nix-config` input).

---

## 15. Side findings (outside the template)

- **Global ignores: removed** after this research. `git.nix` no longer sets
  `programs.git.ignores`, so each repo's `.gitignore` is the whole list and `git add -f` is not
  needed for the template. Secrets go in `.env`, which the template's `.gitignore` covers.
  Existing repos were checked: `engineering-AI-systems` already ignores its token-holding
  `.envrc` itself; `.direnv/` was added to its `.gitignore` and `spotify_to_ytmusic`'s, and to
  `.git/info/exclude` in the team repo `silcrst-team`.
- **`nix-ld.nix` comment** ("pip wheels"): true for uv's Python, false for venvs on a nixpkgs
  Python [nixld-readme#L162-178]. Worth one clarifying word when typhon is installed.
- **nix-config's `nixpkgs-unstable` input tracks `nixos-unstable`.** That branch is gated on NixOS
  tests, not on the darwin jobs that gate `nixpkgs-unstable` [channels.nix#L27-40]
  [release.nix#L164-212]. **Assessment:** helios takes `claude-code` and `opencode` from it, so a
  darwin cache miss is possible right after a bump. Not observed; check before changing.
- **Dependabot now updates `flake.lock` (public repos) and `uv.lock`** [dbot#L33-34]
  [dbot#L58-61] [dbot#L174-178]. This is a possible alternative to `update-flake-lock`
  (best-of-nix §4.3). Not tested.

---

## 16. Limitations (not verified)

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
  - `nix flake init -t github:Ety0011/nix-config#python` (needs the template pushed);
  - the migration steps on real projects (§11.5);
  - Dependabot `nix` and `uv` updates;
  - devenv, uv2nix and pixi themselves.
- **Interactive direnv not used.** Shell hook reloads were not exercised. `direnv exec` evaluates
  the same `.envrc` and the same watch list.
- **Darwin-only sizes.** The 1.3 GiB Python closure is a darwin number; on Linux it is likely
  smaller.

---

## 17. Sources

Metadata and local

- [gh-meta] `gh api repos/<o>/<r>`, `…/releases/latest`, `…/milestones/4` (astral-sh/ty: 98 open,
  737 closed), repository search on 2026-10-30; `gh repo view Ety0011/nix-config` → public;
  direnv `stdlib.sh` at tags v2.37.1 (no `layout_uv`) and v2.38.0 (has it).
- [lock] `nix eval --inputs-from . <input>#<pkg>.version` on this repo @ `70c1710`:
  nixpkgs-26.05-darwin @ `d592aacecd35` and nixpkgs-unstable (`nixos-unstable`) @ `3ec636362e18`.
  python3 3.13.15/3.14.8, uv 0.11.21/0.13.4, ruff 0.15.14/0.17.2, basedpyright 1.39.3/1.39.8,
  pyright 1.1.411/1.1.414, ty 0.0.38/0.0.91, mypy 1.20.1/2.1.0, nix-direnv 3.1.2/3.2.0, direnv
  2.37.1/2.38.2, devenv 2.1.2/2.4.0, pixi 0.68.1. The test projects locked nixpkgs-unstable @
  `e62746b0b472` (uv 0.13.5, python313 3.13.16, nixfmt-tree 2.6.0).
- [local] helios, 2026-10-30:
  - `~/Documents/projects/*` and `~/Documents/master/*`: `flake.nix`, `pyproject.toml`,
    `pixi.toml`, `.venv/pyvenv.cfg`, `.envrc` with values redacted;
  - `~/.zsh_history` counts; `~/.config/git/ignore`; `~/.vscode/extensions`;
  - this repo @ `70c1710`: `modules/features/{git,direnv,nix-ld,nix-tools,nixpkgs}.nix`,
    `modules/users/ety.nix`, `.github/workflows/check.yml`, `git show 9f2a720`;
  - every test in §12.

Nix, flake-parts, import-tree

- [nix-flake.cc] https://github.com/NixOS/nix/blob/8759435f7396e366a9227274751c950cb0a4fc5e/src/nix/flake.cc
  (L546-575, L556-558, L617-669, L876-1007)
- [nix-flake-init] …/src/nix/flake-init.md (L23-41)
- [fp-flake.nix] https://github.com/hercules-ci/flake-parts/blob/024633cd702b10285db5cb19b40ad48d2399ba60/modules/flake.nix
  (L10-31) · flake-parts' own templates: …/flake.nix (L19-48)
- [import-tree] https://github.com/denful/import-tree/blob/eb1b52eaecc57f7c136d07ae8a93e724dfecac46/default.nix (L64)
- [channels.nix] https://github.com/NixOS/infra/blob/d600bd84f8f5ddbf46153a84f7cff5c999397e8e/channels.nix (L27-55)
- [release.nix] https://github.com/NixOS/nixpkgs/blob/3ec636362e1816bc2f0888fa0fa2c69f1bc9e504/pkgs/top-level/release.nix
  (L110-141, L164-212)

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
- [devshell] https://github.com/numtide/devshell/blob/9e29c63dde99a2d80c94b3d024c9768c01544558/README.md (L1-3)
- [flox] https://github.com/flox/flox/blob/da039c11477e210045a7472b15933b55947f9bd1/README.md (L42, L90)
- [devbox] https://github.com/jetify-com/devbox/blob/dc599b1c59dd3e8de890110d74ff6951b96f3f75/README.md (L27-31, L57)

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
- [inix] https://github.com/cachix/install-nix-action/blob/75c75c31ebece974e48ebc36b4ad125bd97bd97b/README.md (L9, L38-52, L73-87)
- [mnc] https://github.com/DeterminateSystems/magic-nix-cache-action/blob/f69a2d3e148e90223fe63ab6e3f6331f2e7e33dc/README.md (L1-30)
- [gh-prices] https://github.com/github/docs/blob/9860344c45e8c0a43970665e3b219a9d0f56c0dd/data/reusables/billing/actions-standard-runner-prices.md (L1-9)
- [gh-billing] …/content/billing/concepts/product-billing/github-actions.md (L127-130)
- [dbot] …/data/reusables/dependabot/supported-package-managers.md (L33-34, L58-61, L174-178) ·
  feature flags `data/features/dependabot-{nix,uv}-support.yml` (`fpt: '*'`)
