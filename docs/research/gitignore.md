# Ignoring files in git: what to list, where, and why

Research date: 2026-11-03. Method: git's own manual was read at the v2.54.0 tag. Each tool's
ignore behaviour was read in its source at the release tag listed in §13 (uv, ruff, pytest, CPython
venv, clangd, CMake, Nix, direnv, nix-direnv, Home Manager). The generic lists (github/gitignore,
gitignore.io) were read at a pinned commit, along with their recent history and pull requests.
Then the tools were run on helios in a scratch directory, and `git status --ignored`,
`git check-ignore -v` and `git clean -ndX` showed what each list catches and what it hides [local].
git config was isolated there (`GIT_CONFIG_GLOBAL`), and nothing in this repo was changed. "Fact"
statements carry a citation; **Assessment** marks my judgement; [local] marks my own tests.
Popularity and familiarity were not used as reasons. Where a list came from (gitignore.io, uv,
GitHub) counts only through what its entries do.

---

## 1. TL;DR

- **A false ignore is silent; a miss is visible.** A missed file shows up in `git status`. A
  wrongly ignored file never does: `git add -A` skips it without a word [local] and every clone
  lacks it. So a project list should hold only patterns that match nothing anyone would want to
  commit, and it should be short enough to read. Add a line when `git status` shows a new kind of
  generated file.
- **Build the list from what your tools actually write**, not from a generic catalogue. The
  generic lists contain false ignores that bite real projects (all tested, §4):
  - github/gitignore's Python list hides `lib/`, `var/`, `downloads/`, `build/` at any depth, plus
    `*.spec`, `*.pot` and, since 2025-06, `.envrc`.
  - Its C/C++/CMake lists hide `Makefile`, `Testing`, `*.a`, `*.out`, `go.mod`, and `*.mod*`
    (Clang's `module.modulemap`).
  - gitignore.io serves a 2023 snapshot whose upstream repo is gone. It hides `pyrightconfig.json`.
- **Many tools now ignore their own output.** uv's `.venv` and `dist/`, Python 3.13+ venvs, ruff,
  pytest and mypy caches, and clangd's index (LLVM 22+) each write a `.gitignore` containing `*`
  into their own directory [uv-venv] [uv-build] [cpython-venv] [ruff-cache] [pytest-cache]
  [clangd-bis]. These need no project line. CPython's `__pycache__/`, CMake build trees and
  direnv's `.direnv/` do not self-ignore, so they do need one [local].
- **Anchor where the location is known.** Write `/build/` and `/result`, not `build/` and `result`.
  Patterns without a slash match at every depth [git-ignore#L94-98]. Remember that macOS repos
  match ignore patterns case-insensitively: `ENV/` hid `env/` [local] [git-core#L29-39].
- **Secrets:** list `.env` and `.env.*`, and re-include `!.env.example`. Never ignore a file that
  holds setup but no secrets (`.envrc` with `use flake`).
- **Lockfiles and pins are committed:** `uv.lock` [uv-layout#L83-85], `flake.lock`, and
  `.python-version`. Never ignore them.
- **Global excludes: yes, but only for files no repository ever tracks, and in addition to (not
  instead of) the project lines.** On helios that means `.DS_Store` and nothing else. git's
  manual puts per-user, per-machine junk in `core.excludesFile` [git-ignore#L42-60]. A global
  pattern can only hide files matching it, so `.DS_Store` can never hide a file a project wants
  committed. The failure this repo hit came from a global `.envrc`, a file projects do track
  (§3.2). That rules out `.envrc`, `.env*`, `.vscode/`, `.venv`, `result` and `build/` as global
  patterns. Editor swap files are not needed: `EDITOR` is `nano` and VS Code writes nothing into
  projects [local].
- **This repo's templates:** the recommended `templates/python/.gitignore` and
  `templates/cpp/.gitignore`, and the one-line Home Manager change, are in §10.

---

## 2. git's ignore semantics

- **Fact:** ignore rules affect untracked files only: "Files already tracked by Git are not
  affected" [git-ignore#L14-17]. To stop tracking a file, run `git rm --cached` [git-ignore#L155-163].
- **Fact, precedence**, highest first. Within one level, "the last matching pattern decides the
  outcome" [git-ignore#L19-40]:
  1. patterns on the command line;
  2. `.gitignore` in the path's directory and its parents. A deeper file overrides a shallower one;
  3. `$GIT_DIR/info/exclude`;
  4. `core.excludesFile`, by default `$XDG_CONFIG_HOME/git/ignore`, else
     `~/.config/git/ignore` [git-ignore#L55-60].
  - Tested: `!keep.log` in `.gitignore` re-included a file that both `.git/info/exclude` and the
    global file excluded with `*.log` [local].
- **Fact, slashes** [git-ignore#L91-111]:
  - A slash at the start or in the middle anchors the pattern to the `.gitignore`'s directory.
    Without one, the pattern "may also match at any level below".
  - A trailing slash matches directories only.
  - Patterns in `info/exclude` and `core.excludesFile` behave as if written at the repo root.
- **Symlinks are not directories to git.** Tested: `result/` does **not** match a `result ->
/nix/store/…` link; `result` and `/result` do [local]. Nix's out-links therefore need the form
  without a slash.
- **Fact, negation:** "It is not possible to re-include a file if a parent directory of that file
  is excluded" [git-ignore#L80-89]. Tested: `.pixi/` followed by `!.pixi/config.toml` leaves the
  file ignored; `.pixi/*` followed by the same negation works [local]. github/gitignore uses the
  second form [gh-python#L126-127].
- **Case:** `git init` on a case-insensitive filesystem (APFS) sets `core.ignoreCase`
  [git-core#L29-39]. Tested on helios: github's `ENV/` matched `src/app/env/`, a source package
  [local].
- **How false ignores stay hidden:** `git add -A` skipped an ignored `.envrc` without a message.
  Only `git add .envrc` by name prints "The following paths are ignored by one of your .gitignore
  files" [local]. To find which rule hid a file, run `git check-ignore -v <path>`.
- **Self-ignoring directories are ordinary nested `.gitignore` files.** `*` in `dir/.gitignore`
  ignores everything in it, the `.gitignore` included, so the directory never appears in
  `git status`. `git clean -ndX` listed `.venv/`, `.ruff_cache/`, `.pytest_cache/` and `dist/`
  either way, with or without root lines for them [local]. `git status` took ≤0.01 s either way,
  so the performance argument in [gh-4289] does not show at this size [local].

---

## 3. Where a pattern belongs

### 3.1 The three places

- **Fact, git's manual** [git-ignore#L42-60]:
  - `.gitignore`: patterns "which should be version-controlled and distributed to other
    repositories via clone (i.e., files that all developers will want to ignore)".
  - `$GIT_DIR/info/exclude`: patterns "specific to a particular repository but which do not need
    to be shared", for example files "specific to one user's workflow".
  - `core.excludesFile`: patterns "a user wants Git to ignore in all situations (e.g., backup or
    temporary files generated by the user's editor of choice)".
- **Fact, GitHub:** the global file is for files like "temporary backup files that your text
  editor creates"; `info/exclude` is for "locally-generated files that you don't expect other
  users to generate" [gh-docs-ignore]. github/gitignore's README says its `Global/` templates
  (editors, tools, OSes) should go "to your global template or merge[d] … into your
  project-specific templates" [gh-readme#L27-31].

### 3.2 The failure mode of global excludes

- **Fact (this repo, before `e7446b3`):** the global list held `.envrc`. A path flake in a git
  repo sees tracked files only. `git add templates/python` therefore skipped
  `templates/python/.envrc`, and `nix flake init` wrote every file except `.envrc` without a
  warning (dev-env.md §4.2, §9).
- Reproduced in a scratch flake repo [local]:
  - A global `.envrc` again dropped the template's `.envrc` from `git add -A`.
  - With github's Python list as the template's own `.gitignore`, both `.envrc` and `lib/helper.py`
    were dropped, and `nix flake new` wrote only `.gitignore` and `README.md`.
  - So the failure is not specific to global files. **Any** ignore source that matches a file the
    repo needs causes it.
- **Assessment, the rule that follows:** a global pattern is safe only if no repository, yours or
  anyone else's, would ever want to track a file matching it. Check candidates against that:

  | Candidate global pattern     | Safe?   | Why                                                                                                            |
  | ---------------------------- | ------- | -------------------------------------------------------------------------------------------------------------- |
  | `.DS_Store`                  | **Yes** | Finder view state; no project ever wants it                                                                    |
  | `*.swp`, `*~`                | Yes     | Not needed on helios: `EDITOR=nano`; Apple's vim (default `directory=.,~/tmp,…`) is unconfigured [local]       |
  | `.envrc`                     | **No**  | Projects commit it (this repo's templates); the cause of §3.2                                                  |
  | `.env`, `.env*`              | No      | Some ecosystems commit `.env`/`.env.[mode]` and ignore only `*.local` [vite-env]; it would hide them in clones |
  | `.vscode/`                   | No      | The templates ship `.vscode/settings.json`, `extensions.json`, `launch.json`                                   |
  | `.venv/`, `build/`, `result` | No      | Real names in some projects; they belong to the project that generates them                                    |

- **Assessment, verdict:** a one-entry global file (`.DS_Store`) costs nothing and protects every
  repo you clone or contribute to whose `.gitignore` lacks it. For example, `spotify_to_ytmusic`
  does not ignore `.DS_Store` [local]. Keep `.DS_Store` in each project's `.gitignore` too: that
  copy protects collaborators on macOS without your global file, and is the one that travels with
  the repo.

---

## 4. Generic lists and their pitfalls

### 4.1 github/gitignore (`Python`, `C`, `C++`, `CMake`, `Nix`) @ `6bb5af7`

- **Fact:** the repo is active. `Python.gitignore` was last changed on 2026-10-30, and in 2025-26
  gained pixi, marimo, Streamlit, Abstra and Zensical entries [gh-python-log]. The GitHub UI's
  template picker is built from it [gh-readme#L3-5].
- **False ignores in Python.gitignore, tested with `git check-ignore -v` [local]:**
  - `lib/` (L17), `var/` (L21), `downloads/` (L14) and `build/` (L11) are unanchored, so they hide
    `src/app/lib/x.py`, `tests/var/`, `docs/downloads/` and `tools/build/gen.py`.
  - `ENV/` (L158) hid `src/app/env/` on macOS (§2).
  - `*.spec` (L33) hides PyInstaller spec files, which are often hand-edited and committed.
  - `*.pot` (L57) hides gettext templates, which are source files.
  - **`.envrc` (L154)**, added by PR #3619 on 2025-06-13. Its reason: ".envrc … can contain
    sensitive information" [gh-3619]. That conflicts with any setup where `.envrc` is committed
    setup, which is direnv's design.
- **Lockfile comments:** `.python-version`, `uv.lock`, `poetry.lock` and `pdm.lock` appear only
  as commented-out lines. The text says it is "generally recommended to include uv.lock" and
  ignoring it is "more commonly" done for libraries [gh-python#L86-102]. uv's own docs make no
  library exception (§7).
- **False ignores in C/C++/CMake, tested [local]:**
  - `*.mod*` (C L46) hid `include/mod/module.modulemap`; `*.mod` (C++ L27) hid `go.mod`.
  - `Makefile` (C++ L50, CMake L6) hides hand-written Makefiles.
  - `Testing` (CMake L5) hides a `Testing` directory.
  - `*.a`, `*.lib` and `*.so` hide vendored prebuilt libraries.
  - `*.out` hid `expected.out` test fixtures.
  - The CMake entries exist for in-source builds. With out-of-source build trees they match nothing
    generated.
- **Useful, low-risk entries:** `CMakeUserPresets.json` (CMake L12) and Nix.gitignore's `result`,
  `result-*` and `.direnv` [gh-nix#L1-6].

### 4.2 gitignore.io (toptal)

- **Fact:** the site renders templates from the `toptal/gitignore` submodule, pinned at
  `0a7fb018`. The last "sync templates" commit was on 2023-07-04, and the repo's last push on
  2024-12-23 [gio-repo]. `github.com/toptal/gitignore` now answers 404 [local].
- **Fact:** `/api/python` (fetched 2026-11-03) is github's 2023 list plus a "Python Patch" adding
  `poetry.toml`, `.ruff_cache/` and **`pyrightconfig.json`** [gio-python]. It has no uv
  commentary and still carries the old `*.py,cover` typo that github fixed in 2025 [gh-3985].
- **False ignore:** `pyrightconfig.json` is pyright's and basedpyright's project config file.
  Ignoring it silently drops type-checker settings from clones (tested) [local].
- **Assessment:** it is a frozen copy of §4.1 with extra patches. It has the same pitfalls, plus
  staleness.

### 4.3 Tool-generated lists: `uv init`

- **Fact, uv 0.13.5:** without `--vcs none`, `uv init` runs `git init` and writes this file if no
  `.gitignore` exists [uv-vcs#L35-75] [uv-vcs#L87-97]. Tested, byte for byte [local]:
  `__pycache__/`, `*.py[oc]`, `build/`, `dist/`, `wheels/`, `*.egg-info`, `.venv`.
- **Assessment:**
  - Short, and it has no `.envrc`.
  - Unanchored `build/` hides `tools/build/`.
  - Several lines cover nothing uv itself produces: `dist/` self-ignores, `uv_build` makes no
    `build/` or `egg-info` (tested) [local], and Python 3 writes `.pyc` only inside `__pycache__/`.
  - It ignores neither `.env` nor `.DS_Store`.

### 4.4 Other generators

- **Assessment:** `gh repo create --gitignore` and GitHub's UI picker serve github/gitignore
  (§4.1). Other web and CLI generators assemble the same upstream templates. No 2024-2026
  generator was found that builds a list from what a project's tools actually write. The trend is
  the opposite one: tools ignore their own output (§8).

---

## 5. What tools create, and what ignores itself

Tested with uv 0.13.5, ruff 0.17.3, pytest 9.2.0, basedpyright 1.40.2, CPython 3.13 (uv-managed),
CMake 4.4.4, Ninja, clangd 22.1.8, direnv 2.37.1, nix-direnv 3.1.2 and Nix 2.34.9 [local].

| Path                                 | Created by                                         | Self-ignoring?                                                                           | Needs a project line?    |
| ------------------------------------ | -------------------------------------------------- | ---------------------------------------------------------------------------------------- | ------------------------ |
| `__pycache__/`                       | CPython import, pytest                             | **No** [local] [pytest-4886]                                                             | **Yes**                  |
| `.venv/` (uv)                        | `uv sync`, `uv venv`                               | Yes, `*` [uv-venv#L214-215]                                                              | Yes, see below           |
| `.venv/` (`python -m venv`)          | Python ≥ 3.13                                      | Yes, by default on the CLI [cpython-venv#L278-289] [cpython-venv#L628-632] [cpython-313] | ″                        |
| `.venv/` (`python -m venv`)          | Python ≤ 3.12, e.g. macOS `/usr/bin/python3` 3.9.6 | **No**: 572 untracked files [local]                                                      | ″                        |
| `.ruff_cache/`                       | ruff                                               | Yes, `*` [ruff-cache#L387]                                                               | No                       |
| `.pytest_cache/`                     | pytest                                             | Yes, `*` [pytest-cache#L38-56]                                                           | No                       |
| `.mypy_cache/`                       | mypy                                               | Yes, `*` [mypy-8193]                                                                     | No                       |
| `dist/`                              | `uv build`                                         | Yes, `*`, unless `--no-create-gitignore` [uv-build#L1335-1352] [uv-cli#L2834-2842]       | No                       |
| `src/*.egg-info/`                    | setuptools backend (`uv sync`)                     | No [local]                                                                               | Only with setuptools     |
| (nothing)                            | basedpyright                                       | n/a: wrote no files [local]                                                              | No                       |
| `.ipynb_checkpoints/`                | Jupyter server on save (Lab/Notebook)              | No                                                                                       | Only with Jupyter Lab    |
| `build/<preset>/`                    | CMake + Ninja                                      | **No**: CMake 4.4.4 writes none [local]                                                  | **Yes**                  |
| `<cdb dir>/.cache/clangd/index/`     | clangd background index                            | Yes, `*` since LLVM 22 [clangd-bis#L42-58] [llvm-170003]                                 | No                       |
| `CMakeUserPresets.json`              | you (personal presets)                             | No; "should NOT be checked in" [cmake-presets#L26-36]                                    | **Yes**                  |
| `.direnv/`                           | direnv layout dir, nix-direnv cache                | **No** [direnv-stdlib#L115-118] [nd-direnvrc#L87-124] [local]                            | **Yes**                  |
| `result`, `result-<out>`, `result-1` | `nix build` out-links (symlinks)                   | No [nix-build#L19-40]                                                                    | **Yes**, no trailing `/` |
| `.DS_Store`                          | Finder                                             | No                                                                                       | Yes (and global)         |

- **Why name `.venv/` although uv self-ignores it:** a `.venv` made by a pre-3.13 Python
  has no inner `.gitignore`. On macOS that is the system `python3`, or any tool calling it.
  Tested: 572 files appeared, and `git add -A` would commit them [local]. A missed line costs a lot
  here and the extra line cannot hide anything else, so it stays.
- **Why not name the other self-ignoring dirs:**
  - **Assessment:** each tool maintains its own rule, so a renamed cache stays ignored with no
    edit.
  - A line in the list would only repeat the rule, and would tempt the reader to copy the rest of
    a generic list.
  - A one-line comment naming them answers "why is `.ruff_cache/` missing?".
  - Counter-view, for the record: [gh-4289] argues for root lines (IDE folder exclusion,
    performance). The performance part did not show at this scale [local].
- **Where clangd's index goes:** "When a CDB root is found, shards are stored in
  `$ROOT/.cache/clangd/index/`" [clangd-bis#L104-131]. With
  `.clangd: CompilationDatabase: build/debug`, that root was `build/debug/`. Tested: the index
  landed in `build/debug/.cache/clangd/index/`, with its own `.gitignore`, and no top-level
  `.cache/` was created [local].

---

## 6. Secrets

- **Fact:** direnv's `dotenv_if_exists` with no argument loads `$PWD/.env` only
  [direnv-stdlib#L253-265].
- **Assessment, the pattern:** `.env`, `.env.*`, `!.env.example`.
  - Unanchored, so a `services/api/.env` is caught too.
  - `.env.*` catches `.env.local` and `.env.production`, the names other ecosystems use for
    secrets [vite-env].
  - The negation works because the parent directory is not excluded (§2).
  - Tested: `.env`, `.env.local`, `.env.sample` and `svc/.env` ignored; `.env.example` and
    `.envrc` not [local].
  - Trade-off: `.env.sample` and `.env.template` are hidden too. A secret committed to a public
    history means rotating it; a hidden sample file means one `git add -f`. The asymmetry favours
    ignoring.
- **Do not ignore `.envrc` when it holds no secrets.** Keep secrets out of it (`.env`), then
  commit it. If a project does put secrets in `.envrc`, that project's `.gitignore` says so, as
  `engineering-AI-systems` does (dev-env.md §12). Never say it globally (§3.2).
- `CMakeUserPresets.json` is personal, not secret, but is never committed either (§5).

---

## 7. Lockfiles and version pins

| File                    | Commit? | Evidence                                                                                                                                                                                                                                         |
| ----------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `uv.lock`               | **Yes** | "This file should be checked into version control" [uv-layout#L83-85]. A CI step `uv sync --locked` fails without it.                                                                                                                            |
| `.python-version`       | **Yes** | uv reads it as the default Python request [uv-pyver#L61-72]. `uv init` creates it and its `.gitignore` does not list it [uv-vcs#L87-97]. setup-uv reads it in CI. github's "ignore for libraries" comment is a pyenv-era note [gh-python#L86-89] |
| `flake.lock`            | **Yes** | Nix creates it "to ensure reproducibility" [nix-flake#L610-615]. Uncommitted, each machine locks `nixpkgs-unstable` at whatever rev is current (tested: 2026-11-03 → `9a6cbf47`) [local]                                                         |
| `CMakePresets.json`     | **Yes** | "may be checked into a version control system" [cmake-presets#L26-36]                                                                                                                                                                            |
| `CMakeUserPresets.json` | **No**  | "should NOT be checked in" [cmake-presets#L26-36]                                                                                                                                                                                                |
| `pixi.lock` (not here)  | Yes     | github comments it in; `.pixi/*` with `!.pixi/config.toml` is ignored [gh-python#L121-127]                                                                                                                                                       |

---

## 8. Newer practice (2018 → 2026)

| Year      | Change                                                                              | Source                         |
| --------- | ----------------------------------------------------------------------------------- | ------------------------------ |
| 2018-09   | pytest writes `.pytest_cache/.gitignore` (`*`)                                      | [pytest-3982]                  |
| 2020-01   | mypy writes its cache `.gitignore`                                                  | [mypy-8193]                    |
| 2022-09   | ruff writes `.ruff_cache/.gitignore`                                                | [ruff-208]                     |
| 2023-09   | CPython adds venv SCM ignore files, default on the CLI from 3.13 (released 2024-10) | [cpython-108125] [cpython-313] |
| 2024      | uv 0.4.18: `uv build` writes `dist/.gitignore`; uv venvs always carry one           | [uv-chlog-0.4] [uv-venv]       |
| 2025-06   | github/gitignore Python list adds `.envrc`; marimo entries                          | [gh-3619] [gh-python-log]      |
| 2025-09   | github/gitignore adds pixi (`.pixi/*`, `!.pixi/config.toml`)                        | [gh-python-log]                |
| 2025-12   | clangd writes `.cache/clangd/index/.gitignore` (LLVM 22)                            | [llvm-170003]                  |
| 2023→2026 | gitignore.io templates frozen since 2023-07; upstream repo gone                     | [gio-repo]                     |

- **Assessment:** caches are moving toward ignoring themselves, which shrinks what a project list
  must carry. Generic lists move the other way: they keep growing by adding tools. Both trends
  favour a short list built from evidence.

---

## 9. Comparing list strategies (general)

Rated against a uv + ruff + pytest Python project and a CMake-presets + clangd C/C++ project, both
using direnv and Nix.

| Strategy                                | False ignores                                                                                 | Misses                                                | Secrets           | Maintenance                               | Clarity                       |
| --------------------------------------- | --------------------------------------------------------------------------------------------- | ----------------------------------------------------- | ----------------- | ----------------------------------------- | ----------------------------- |
| github/gitignore as-is                  | **Many**: `lib/`, `var/`, `build/`, `.envrc`, `*.spec`, `Makefile`, `*.mod*`, `*.a`… (tested) | `.direnv/`, `result` (in Nix.gitignore, not Python/C) | `.env` only       | Low (copy); drifts from upstream          | 200+ lines, mostly irrelevant |
| gitignore.io as-is                      | Same, plus `pyrightconfig.json`                                                               | Same                                                  | `.env` only       | Frozen 2023                               | Same                          |
| `uv init`'s list                        | Unanchored `build/`                                                                           | `.env`, `.direnv/`, `.DS_Store`, `result`             | **None**          | Low                                       | Good, 7 lines                 |
| Evidence-built (§10)                    | None found (tested)                                                                           | None in the tested workflows; add-when list in §10.3  | `.env`, `.env.*`  | A line per new tool, seen in `git status` | Each line has a reason        |
| Global only (no project list)           | None, if global is junk-only                                                                  | Everything for collaborators and other machines       | None for others   | One file                                  | Hidden from clones            |
| **Global `.DS_Store` + evidence-built** | None                                                                                          | As evidence-built                                     | As evidence-built | As evidence-built, plus one HM line       | Best                          |

---

## 10. Applied to this repo

### 10.1 Repo-specific facts that shape the lists

- **The templates' `.gitignore` files are live inside nix-config.** Nested `.gitignore` files
  apply to the whole repo: `git check-ignore -v templates/cpp/build/x` reports
  `templates/cpp/.gitignore:5:build/` [local]. The flake behind `nix flake init` sees tracked files
  only (dev-env.md §4.2). So any template rule matching a file the template ships drops that file
  silently. Reproduced with github's list: `.envrc` and `lib/helper.py` were lost (§3.2) [local].
  **Check after any template edit:**
  `git ls-files --others --ignored --exclude-standard templates/` must print nothing. It printed
  nothing at `208dbdf` [local].
- **The global ignores were removed on purpose** (`e7446b3`), because a global `.envrc` hid
  `templates/python/.envrc`. A global `.DS_Store` cannot reproduce that (§3.2).
- **nix-direnv's cache is `.direnv/`**, created at the `.envrc`'s level, with no inner ignore
  [local]. **`path:./nix` copies only `nix/`**, so ignore rules play no part in what Nix copies
  (dev-env-no-git.md). Ignore rules only decide what git commits.
- **`nix build` makes `result`, `result-<output>` and `result-1` symlinks** in the current
  directory [nix-build#L19-40]. The templates run Nix from the project root (`path:./nix`), so
  anchor them. Unanchored `result-*` would hide fixtures such as `tests/data/result-1.json`.

### 10.2 Recommended files

`templates/python/.gitignore`:

```gitignore
# macOS Finder metadata
.DS_Store

# direnv/nix-direnv cache, and `nix build` links (run from the project root)
.direnv/
/result
/result-*

# Secrets: .envrc loads .env. Commit an .env.example instead.
.env
.env.*
!.env.example

# Bytecode: CPython writes no ignore file into __pycache__/
__pycache__/

# Virtual environment. uv (and Python 3.13+ venv) put a "*" .gitignore
# inside; `python3 -m venv` with an older Python does not.
.venv/

# Not listed: each writes its own "*" .gitignore.
# .ruff_cache/ (ruff), .pytest_cache/ (pytest), dist/ (uv build)
```

`templates/cpp/.gitignore`:

```gitignore
# macOS Finder metadata
.DS_Store

# direnv/nix-direnv cache, and `nix build` links (run from the project root)
.direnv/
/result
/result-*

# Secrets: .envrc loads .env. Commit an .env.example instead.
.env
.env.*
!.env.example

# CMake preset build trees (build/<preset>/): objects, _deps/,
# compile_commands.json, and clangd's index (build/debug/.cache/clangd/)
/build/

# Personal presets; CMake's manual says never to commit this file
/CMakeUserPresets.json
```

Changes from the current lists, and why:

| Change                                       | Reason                                                                                                             |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `result` → `/result` + `/result-*`           | multi-output and multi-installable links [nix-build#L19-40]; anchoring avoids hiding fixtures                      |
| `+ .env.*`, `+ !.env.example`                | secrets under other `.env` names (§6)                                                                              |
| Python: `− .pytest_cache/`, `− .ruff_cache/` | self-ignoring [pytest-cache] [ruff-cache]; kept as a comment                                                       |
| C++: `− .cache/`                             | clangd's index lands in `build/debug/.cache/` and self-ignores [local] [clangd-bis]; nothing else writes `.cache/` |
| C++: `build/` → `/build/`                    | presets put every tree at `${sourceDir}/build/` (`CMakePresets.json`)                                              |
| C++: `+ /CMakeUserPresets.json`              | CMake's manual [cmake-presets#L26-36]; replaces dev-env-cpp's "add it if you create one"                           |

Tested end to end [local]:

- **Python**, after `uv init --app`, `uv add --dev …`, ruff, basedpyright, pytest and `uv build`:
  `git add -A` tracked exactly `.env.example .envrc .github/… .gitignore .python-version .vscode/…
README.md nix/flake.{lock,nix} pyproject.toml src/… tests/test_x.py uv.lock`.
  A system-Python `.venv` was ignored.
- **C/C++**, after `cmake --workflow --preset debug` and `--preset ci` and a clangd session:
  ignored were `.DS_Store .direnv/ .env CMakeUserPresets.json build/`; everything else stayed
  visible.

nix-config's own `.gitignore` holds only the out-links, anchored as `/result` and `/result-*`,
because it applies inside `templates/` too. `.DS_Store` is left to the global ignore: every Host
that uses this repo gets it from `git.nix`, and nobody else works in the repo. The templates keep
their `.DS_Store` line, because their projects get cloned on machines without it. The repo root
has no `.envrc` or `.env`, so nothing else belongs there.

### 10.3 Add when (not in the lists, on purpose)

| Line                     | Add when                                                                                   |
| ------------------------ | ------------------------------------------------------------------------------------------ |
| `*.egg-info/`            | you switch the build backend to setuptools (tested: `src/<pkg>.egg-info/` appears) [local] |
| `.ipynb_checkpoints/`    | you run Jupyter Lab/Notebook; VS Code's notebook editor was not seen to write them (§12)   |
| `/dist/`                 | you build with a tool other than `uv build` (pypa/build writes no ignore file; not tested) |
| `/compile_commands.json` | you symlink the database to the root instead of using `.clangd`                            |
| `.envrc` (!)             | never in a template; only in a project whose `.envrc` holds secrets                        |

### 10.4 Global excludes for helios

Re-add a junk-only global list in `modules/features/git.nix`. Home Manager writes it to
`~/.config/git/ignore`, git's default `core.excludesFile` [hm-git#L150-158] [hm-git#L402-404]
[git-ignore#L55-60]:

```nix
# Only files no repo ever tracks. Never .envrc, .env, .vscode/, .venv:
# a global match silently drops a file from every repo and template
# (docs/research/gitignore.md §3.2).
ignores = [ ".DS_Store" ];
```

Applied in `modules/features/git.nix`, with the header comment changed to match.

### 10.5 Follow-ups in other docs (done)

- dev-env-cpp.md §6 (L401-402) says the clangd index goes "next to the database's project, hence
  `.cache/`". With `.clangd` pointing at `build/debug`, it goes to `build/debug/.cache/` and has
  ignored itself since LLVM 22 [local] [clangd-bis].
- dev-env-python.md (L350-361) and dev-env-cpp.md (L664-673) quote the current lists verbatim, and
  L807 of dev-env-cpp.md says to add `CMakeUserPresets.json` later. Update them if §10.2 is
  adopted.

---

## 11. What was tested (helios, aarch64-darwin, macOS 26, git 2.54.0, Nix 2.34.9+1)

Scratch dir only; `GIT_CONFIG_GLOBAL`, `XDG_DATA_HOME`, `UV_CACHE_DIR` and `UV_PYTHON_INSTALL_DIR`
were redirected there [local].

| Command                                                                                       | Outcome                                                                                                        |
| --------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `nix flake new -t ~/nix-config#python`, `git init`, `direnv allow`, first load                | `.direnv/` created with no inner `.gitignore`; `nix/flake.lock` → nixpkgs `9a6cbf47` (2026-11-03)              |
| `uv init --app --vcs none`; `uv add --dev ruff basedpyright pytest`; ruff/basedpyright/pytest | `.venv/`, `.ruff_cache/`, `.pytest_cache/` each with `*` `.gitignore`; `__pycache__/` (root, `tests/`) without |
| same, with the project `.gitignore` removed                                                   | status listed `.direnv/`, `__pycache__/`; not `.venv`, `.ruff_cache`, `.pytest_cache`                          |
| `uv build`                                                                                    | `dist/.gitignore` = `*`; no `build/`, no `egg-info` (uv_build backend)                                         |
| `uv init` (git) in an empty dir                                                               | `.gitignore` = the 7-pattern list in §4.3                                                                      |
| `uv init --lib --build-backend setuptools`; `uv sync`; `uv build`                             | `src/uvst.egg-info/` (no ignore file); no `build/`                                                             |
| `/usr/bin/python3 -m venv .venv` (3.9.6) in a repo                                            | no inner `.gitignore`; 572 untracked files                                                                     |
| `cmake --workflow --preset debug` and `ci` (CMake 4.4.4, Ninja)                               | `build/debug`, `build/ci`; no `.gitignore` in them                                                             |
| clangd 22.1.8 `--background-index` LSP session, 15 s                                          | index in `build/debug/.cache/clangd/index/` with `*` `.gitignore`; no root `.cache/`                           |
| `git check-ignore` with `result/` vs `result` vs `/result` on symlinks                        | `result/` does not match a symlink; `/result` misses `nix/result`                                              |
| `.env`, `.env.*`, `!.env.example`                                                             | `.env`, `.env.local`, `.env.sample`, `svc/.env` ignored; `.env.example`, `.envrc` not                          |
| `.pixi/` vs `.pixi/*` then `!.pixi/config.toml`                                               | first stays ignored; second re-includes                                                                        |
| precedence: `*.log` in global + `info/exclude`, `!keep.log` in `.gitignore`                   | `keep.log` included                                                                                            |
| `git add -A` with `.envrc` ignored; `git add .envrc`                                          | silently skipped; explicit add errors                                                                          |
| github Python / C+C+++CMake lists, gitignore.io python on decoy files                         | hits listed in §4.1–4.2 (incl. `ENV/` → `env/` via `core.ignoreCase`)                                          |
| scratch flake repo, template `.gitignore` = github Python list; `git add -A`; `nix flake new` | `.envrc` and `lib/helper.py` untracked and absent from the new project                                         |
| same repo, global excludes `.envrc`                                                           | `.envrc` untracked again                                                                                       |
| `git clean -ndX` with full vs minimal list                                                    | identical: `.direnv/ .pytest_cache/ .ruff_cache/ .venv/ __pycache__/ dist/ tests/__pycache__/`                 |
| `git status` timing, full vs minimal list                                                     | ≤0.01 s both                                                                                                   |
| recommended §10.2 lists in both scratch projects                                              | tracked sets as in §10.2                                                                                       |
| nix-config: `git check-ignore -v templates/…`; `ls-files --others --ignored … templates/`     | template rules apply in nix-config; no ignored file under `templates/`                                         |
| own repos (`silcrst-team`, `spotify_to_ytmusic`, `engineering-AI-systems`)                    | no tracked `.DS_Store`; `spotify_to_ytmusic` does not ignore it                                                |

---

## 12. Limitations (not verified)

- VS Code's notebook editor writing `.ipynb_checkpoints/`: not run. A code search of
  `microsoft/vscode-jupyter` for `ipynb_checkpoints` found nothing [local].
- `python -m build` (pypa/build) `dist/`: a code search of `pypa/build` found no `.gitignore`
  writing outside tests [local]. Not run.
- mypy's cache ignore: read from the PR [mypy-8193], not run (mypy is not in the setup).
- Older clangd (Apple's `/usr/bin/clangd` 17) writes no index `.gitignore`. Its index would
  still land under `build/debug/` with this `.clangd`, but that was not run.
- typhon (Linux, case-sensitive filesystem) was not tested. Only the `core.ignoreCase` notes
  differ there.

---

## 13. Sources

Local

- [local] helios, 2026-11-03: the runs in §11. Tool versions as in §5. `EDITOR=nano`; Apple vim 9.1
  with `directory=.,~/tmp,/var/tmp,/tmp`; `~/.config/git/` holds only `config`. This repo @
  `208dbdf`, `git log -p modules/features/git.nix` (`e7446b3` removed the global list
  `.direnv/ .envrc .venv/ .DS_Store *.swp`).

git v2.54.0 @ `94f057755b7941b321fd11fec1b2e3ca5313a4e0`

- [git-ignore] https://github.com/git/git/blob/94f057755b7941b321fd11fec1b2e3ca5313a4e0/Documentation/gitignore.adoc
  (L14-17, L19-40, L42-60, L80-111, L155-163)
- [git-core] …/Documentation/config/core.adoc (L29-39, `core.ignoreCase`)

GitHub

- [gh-docs-ignore] https://docs.github.com/en/get-started/git-basics/ignoring-files (fetched 2026-11-03)
- github/gitignore @ `6bb5af7a1b050e5add3a71b6e6365c93498822ac` (2026-10-30):
  [gh-python] https://github.com/github/gitignore/blob/6bb5af7a1b050e5add3a71b6e6365c93498822ac/Python.gitignore
  (L11-33, L45, L56-57, L86-102, L121-127, L152-160, L211-212) · [gh-c] …/C.gitignore (L20-46) ·
  [gh-cpp] …/C++.gitignore (L27, L41-52, L67-68) · [gh-cmake] …/CMake.gitignore (L1-12) ·
  [gh-nix] …/Nix.gitignore (L1-6) · [gh-macos] …/Global/macOS.gitignore (L2) ·
  [gh-vscode] …/Global/VisualStudioCode.gitignore (L2-8) · [gh-readme] …/README.md (L3-5, L19-35)
- [gh-python-log] https://github.com/github/gitignore/commits/main/Python.gitignore (2024-12 → 2026-10:
  `7b268f6` marimo 2025-06-12, `f6eef37` pixi 2025-09-05, `0ed6a1a` uv comment 2025-07-26,
  `b5bb14f` 2026-10-30)
- [gh-3619] https://github.com/github/gitignore/pull/3619 ("Add direnv .envrc to python gitignore",
  merged 2025-06-13, `b4f994b118f6`) · [gh-3985] …/pull/3985 (`*.py,cover` → `*.py.cover`,
  2025-06-18) · [gh-4289] …/pull/4289 (`.ruff_cache/`, merged 2025-01-17; discussion of
  self-ignoring caches)

gitignore.io

- [gio-repo] https://github.com/toptal/gitignore.io @ `fd3331d935ac5029c59d4f4455c4bd1b29dcb3b1`
  (last push 2024-12-23), `.gitmodules` → `toptal/gitignore`, submodule pinned at `0a7fb01801c6`;
  last "sync templates" `7c23b88207f0` (2023-07-04); https://github.com/toptal/gitignore → 404
  on 2026-11-03
- [gio-python] https://www.toptal.com/developers/gitignore/api/python and `…/api/c,c++,cmake`
  (fetched 2026-11-03; "Python Patch" L166-174)

uv 0.13.5 @ `46776a95d6686ac0160c10611327ce491e6b202f`

- [uv-vcs] https://github.com/astral-sh/uv/blob/46776a95d6686ac0160c10611327ce491e6b202f/crates/uv-configuration/src/vcs.rs (L35-75, L87-97)
- [uv-venv] …/crates/uv-virtualenv/src/virtualenv.rs (L214-215)
- [uv-build] …/crates/uv-build-commands/src/lib.rs (L1335-1352) · [uv-cli] …/crates/uv-cli/src/lib.rs (L2834-2842)
- [uv-layout] …/docs/concepts/projects/layout.md (L30-36, L83-85) · [uv-pyver] …/docs/concepts/python-versions.md (L61-72)
- [uv-chlog-0.4] …/changelogs/0.4.x.md (L677-683, 0.4.18: "Add `.gitignore` file to `uv build` output directory")

Other tools

- [ruff-cache] https://github.com/astral-sh/ruff/blob/ba65abf8ba7bfbcc059f7fb9712be5ba9cab6abc/crates/ruff/src/cache.rs (L387; 0.17.3) · [ruff-208] https://github.com/astral-sh/ruff/pull/208 (2022-09-16)
- [pytest-cache] https://github.com/pytest-dev/pytest/blob/ae1d0ff57b8bd4252da9ade7353523ac0ac73281/src/_pytest/cacheprovider.py (L38-56; 9.2.0) · [pytest-3982] https://github.com/pytest-dev/pytest/pull/3982 (2018-09-15) · [pytest-4886] https://github.com/pytest-dev/pytest/issues/4886
- [mypy-8193] https://github.com/python/mypy/pull/8193 (2020-01-21)
- [cpython-venv] https://github.com/python/cpython/blob/60403a5409ff2c3f3b07dd2ca91a7a3e096839c7/Lib/venv/__init__.py (L278-289, L628-632; v3.13.0) · [cpython-313] …/Doc/whatsnew/3.13.rst (L1408-1415) · [cpython-108125] https://github.com/python/cpython/pull/108125 (2023-09-15)
- [clangd-bis] https://github.com/llvm/llvm-project/blob/ca7933e47d3a3451d81e72ac174dcb5aa28b59d1/clang-tools-extra/clangd/index/BackgroundIndexStorage.cpp (L42-58, L104-131; llvmorg-22.1.8) · [llvm-170003] https://github.com/llvm/llvm-project/pull/170003 (2025-12-15)
- [cmake-presets] https://github.com/Kitware/CMake/blob/2e0b3aec14fe2e3e555faac4698e281749aae4b5/Help/manual/cmake-presets.7.rst (L26-36; v4.4.4)
- [nix-flake] https://github.com/NixOS/nix/blob/5fb7eb7d64ba7b78819aa3ac6a7fdd21354910fc/src/nix/flake.md (L610-615; 2.34.9) · [nix-build] …/src/nix/build.md (L19-40)
- [direnv-stdlib] https://github.com/direnv/direnv/blob/7590ee2442104060bb11eedebd7bd6daf3d88fcd/stdlib.sh (L115-118, L253-265; v2.37.1)
- [nd-direnvrc] https://github.com/nix-community/nix-direnv/blob/d0ccbf8cb4b628a7a2e49c655d75fda7f7e4437c/direnvrc (L87-124; 3.1.2)
- [hm-git] home-manager `release-26.05` @ `24f2190587513b9c2f73db112a17844ae912d965`, https://github.com/nix-community/home-manager/blob/24f2190587513b9c2f73db112a17844ae912d965/modules/programs/git.nix (L150-158, L402-404)
- [vite-env] https://vite.dev/guide/env-and-mode (fetched 2026-11-03: "`.env.*.local` files are local-only … add `*.local` to your `.gitignore`")
