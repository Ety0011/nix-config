# Per-project dev environments: folders without git

Research date: 2026-11-03. This file extends [dev-env.md](dev-env.md),
[dev-env-python.md](dev-env-python.md) and [dev-env-cpp.md](dev-env-cpp.md). It answers one question:
how should `templates/python` and `templates/cpp` work in a folder that is not a git repository, and
is avoiding git the best trade-off? Method: claims were followed to the code that owns them, at the
commits in §11: Nix 2.34.9 (what helios runs), 2.35.4 and master; nix-direnv 3.1.2 (helios) and
master; direnv's stdlib; uv; treefmt 2.6.0; and nixpkgs' `nixfmt-tree`. Every design was then built
and run on helios in the scratchpad, from `nix flake init -t /Users/ety/nix-config#<lang>` against
the uncommitted work in progress (WIP), with direnv's allow list and uv's caches redirected there
(§9) [local]. Nothing in the repo, in `templates/` or in your projects was changed. "Fact"
statements carry a citation; **Assessment** marks my judgement. Familiarity was not used as a reason
for any pick.

---

## 1. TL;DR

- **Recommended design: keep the WIP's `nix/` subfolder, but load it as `path:./nix`, not `./nix`.**
  The `.envrc` says `use flake path:./nix`, CI says `nix develop path:./nix -c …`, and every Nix
  command you type names `path:./nix`. Nix then copies only `nix/` (4–8 KiB) into the store, the
  same store path with or without git, tracked or not (§3, tested).
- **Why not `./nix`, as the WIP has it.** Without git it is identical. With git, `./nix` becomes
  `git+file:<repo>?dir=nix`: it fails until `nix/flake.nix` is tracked, and in Nix 2.34 it copies
  _every tracked file of the repo_ into the store, which nix-direnv then roots (§3.2, tested). So
  the WIP still breaks the moment git appears, for example when `uv init` creates a repo.
- **Is avoiding git the right trade-off? Yes, on merit.** git adds no safety the flake needs here:
  `flake.lock` pins the same with either fetcher, and nix-direnv roots the shell the same way. The
  only costs are ergonomic: Nix commands take `path:./nix`, and `nix fmt` runs from `nix/` (§5).
- **Two more fixes, found while testing:**
  - **`nix fmt` walks all of `/nix/store` outside git.** nixfmt-tree's treefmt falls back to the
    folder of its config file, which is in the store. One run took 59 s and failed (§4.3). The
    fix is `nixfmt-tree.override { settings.tree-root-file = "flake.nix"; }` (tested).
  - **`uv init` creates a git repo by default.** The welcome text should say `--vcs none`, or
    `--bare`, which implies it (§6.2).
- **Nothing to revert.** Keep the move of each `flake.nix` into `nix/`. Change the `use flake` and
  `nix develop` refs, the `formatter` line, `welcomeText` and the three docs (§10).
- **No ADR.** Each project can undo this alone, which fails the bar in
  [dev-env.md §11](dev-env.md).

---

## 2. The problem, restated with evidence

- **Fact:** a path-like flake ref (`.`, `./nix`) becomes `git+file:` if a `.git` exists in the
  directory or any parent, and `path:` otherwise [nix-flakeref#L171-215]. Nix's own release note
  says the `path:` case "copied the whole directory to the store, … untracked files included"
  [rl-next-hg#L5-6].
- **Fact:** the `path:` fetcher serialises the whole directory with `defaultPathFilter`, which
  accepts every file [nix-path#L156-162] [nix-archive#L39]. `.gitignore` plays no part. Tested: a
  root flake next to a 64 MiB `junk.bin` gave a 64 MiB store path, although `.gitignore` listed
  `junk.bin` [local].
- **Fact:** in a git repo the fetcher lists files through `git status` with unmodified files
  included and untracked files left out. A file outside that list fails with "Path '…' is not
  tracked by Git" [nix-git-utils#L539-570] [nix-git#L768-784].
- **So** the old workflow needed `git init` before `nix flake init`
  ([dev-env-python.md §9.3](dev-env-python.md)). Your NLP folder holds about 10 GiB of
  checkpoints and a 1.3 GiB `.venv`. There, a root flake without git would copy all of it on every
  re-evaluation.

---

## 3. Fetchers: what gets copied, and from where

### 3.1 Without git

| Flake ref (no `.git` anywhere above) | Resolves to                  | Store copy | Source                   |
| ------------------------------------ | ---------------------------- | ---------- | ------------------------ |
| `.` with `flake.nix` at the root     | `path:<root>`                | 64 MiB     | [local] [nix-flakeref]   |
| `./nix`                              | `path:<root>/nix`            | 4 KiB      | [local]                  |
| `path:./nix`                         | `path:<root>/nix`            | 4 KiB      | [local] [nix-flakeref-u] |
| `.?dir=nix`                          | error: no `flake.nix` in `.` | —          | [local] [nix-flakeref]   |
| `path:.?dir=nix`                     | `path:<root>`, subdir `nix`  | 64 MiB     | [local]                  |

- **Fact:** a relative `path:` URL is made absolute against the current directory
  [nix-flakeref-u#L245-262].
- **Fact:** the flake's own source is fetched, and copied, before `flake.nix` is evaluated
  [nix-flake-get#L368-406] [nix-paths#L23-44]. So no `builtins.path` filter inside the flake can
  shrink its own copy. The `dir=` parameter only names a subdirectory of an input that is still
  fetched whole.
- **Assessment:** the subfolder is the only lever, and it works.

### 3.2 With git: `./nix` versus `path:./nix`

- **Fact:** inside a repo, `./nix` becomes `git+file:<repo>?dir=nix` [nix-flakeref#L171-191].
  The input is the whole repo; `dir` only picks where `flake.nix` sits.
- **Tested** (repo with a tracked 64 MiB file and `nix/flake.nix`) [local]:

  | State of `nix/flake.nix`                           | `./nix`                                        | `path:./nix` |
  | -------------------------------------------------- | ---------------------------------------------- | ------------ |
  | untracked                                          | "Path 'nix/flake.nix' … is not tracked by Git" | works, 4 KiB |
  | `git add -N`, no commit                            | works; store path holds `junk.bin` (64 MiB)    | works, 4 KiB |
  | tracked, big file untracked                        | works, 4 KiB                                   | works, 4 KiB |
  | `nix flake archive --json` (what nix-direnv roots) | 64 MiB path                                    | 4 KiB path   |

- **Fact:** `git add --intent-to-add` is enough, and no commit is needed. `nix flake init` relies
  on this: it runs `git add --intent-to-add --force` on what it writes, but only when `.git` is in
  the target directory itself [nix-init#L961-973].
- **Fact:** `path:./nix` gave the same store hash with and without git (`x0hrbv5y…` for the bare
  fixture, `qzg00xs6…` for the Python template's `nix/`) [local].

### 3.3 Lazy trees: does a newer Nix change this?

- **Fact:** Nix 2.35.0 (2026-06-22) "copies sources to the store more lazily": a flake input is
  hashed, not copied, unless its path ends up in a derivation [rl-2.35#L1-30] [nix-paths-2.35#L64-89].
  The change is commit `891ef140b856`, PR #15711 [nix-15711].
- **Fact:** the same note excludes `path:` inputs [rl-2.35#L9]. The `path:` fetcher at master still
  dumps the directory into the store [nix-path-master#L142-180].
- **Fact:** helios runs 2.34.9; `nixVersions.latest` is 2.35.3 in both 26.05 and unstable, and the
  default `nix` is 2.34.9 in both [lock].
- **Assessment:** lazy trees would help a git root flake: it hashes all tracked files instead of
  copying them, but still reads them on each evaluation. They do nothing for a root flake without
  git. The `nix/` folder stays right after any upgrade.

---

## 4. Nix commands with the flake in `nix/`

### 4.1 `nix develop`, `nix flake update`, `nix flake check`

All tested, with and without git [local]:

| Command (from the project root)       | No git                                | Git, `nix/` untracked | Git, committed (fresh clone) |
| ------------------------------------- | ------------------------------------- | --------------------- | ---------------------------- |
| `nix develop path:./nix -c …`         | ok (resolves exactly as `./nix` does) | ok                    | ok                           |
| `nix develop ./nix -c …`              | ok (via direnv and `nix build`)       | "not tracked" error   | ok                           |
| `nix flake update --flake ./nix`      | ok, writes `nix/flake.lock`           | not run (would error) | not run                      |
| `nix flake update --flake path:./nix` | ok                                    | ok                    | not run                      |

- **Fact:** the lock file goes next to `flake.nix`, in `nix/` [local].
- `nix flake check --no-build --all-systems path:./nix` evaluated both systems for both templates
  [local].

### 4.2 `nix fmt`

- **Fact:** `nix fmt` always evaluates the installable `.`; it takes no flake argument
  [nix-formatter#L74-79]. It sets `PRJ_ROOT` to the flake's source path [nix-formatter#L83-97]
  [nix-fmt-md#L11-13]. For a git input, that path is the repo root [nix-git#L472-475].
- **Tested from the project root:** without git, "could not find a flake.nix file"; in git, "is not
  part of a flake" [local]. **So `nix fmt` runs from `nix/`.** In git that also needs `nix/` tracked,
  because `.` is then a `git+file:` ref.

### 4.3 The `/nix/store` walk (affects the current template too)

- **Fact:** nixfmt-tree is `treefmt.withConfig`, and the wrapper adds only `--config-file
<store path>` [nixfmt-tree#L23-46] [tf-wrapper#L40-43].
- **Fact:** treefmt picks its tree root from `--tree-root`, `--tree-root-file` or `--tree-root-cmd`.
  Failing those it tries `git rev-parse --show-toplevel`, then `jj`. Last, it takes "the directory
  containing the config file" [tf-config#L281-379] [tf-config#L124-128].
- **Fact:** `PRJ_ROOT` only steers where treefmt _looks for a config file_ [tf-root#L136-140]. Its
  env binding for the tree root reads `TREEFMT_PRJ_ROOT`, because of the `treefmt` env prefix
  [tf-root#L82-84] [tf-config#L171-173].
- **Tested:** `nix fmt` in `nix/` without git logged "tree root: /nix/store". It walked the store
  for 59 s, formatted nothing, and exited with "formatting failures detected". A misformatted
  `nix/bad.nix` was left as it was [local]. The store is root-owned and read-only, so nothing was
  damaged.
- **Assessment:** this also hits today's root-flake template in any folder without git, by the same
  code path (inferred, not run). In a git repo it never shows.
- **Fix, tested in both modes:** `pkgs.nixfmt-tree.override { settings.tree-root-file = "flake.nix"; }`.
  Run from `nix/`, it logged "tree root: …/nix", formatted `nix/bad.nix`, and left `../outside.nix`
  alone [local]. The edited `flake.nix` passes `nixfmt --check`, `statix check` and
  `deadnix --fail`, the checks nix-config's own treefmt runs on `templates/` [local].
- **Alternative:** `nixfmt nix/flake.nix` from the project root works anywhere. nixfmt is
  installed globally (`modules/features/nix-tools.nix` L12). Collaborators may not have it, so keep
  the flake's formatter.

---

## 5. nix-direnv with a subfolder flake

- **Fact:** `use flake <ref>` strips a leading `path:` and any `#attr` to get `flake_dir`. It then
  watches `$flake_dir/flake.nix`, `flake.lock` and `devshell.toml` [nd-direnvrc#L276-298]. Both
  `./nix` and `path:./nix` therefore watch `nix/flake.nix` and `nix/flake.lock`. The same holds at
  master [nd-direnvrc-master#L283-304].
- **Fact:** after a successful evaluation it roots the shell profile, and every store path from
  `nix flake archive --json <ref>`: the flake's own source plus its inputs
  [nd-direnvrc#L343-363]. It drops the previous roots first [nd-direnvrc#L345].
- **Tested:** with `path:./nix`, `.direnv/flake-inputs/` held the `nix/` source (8 KiB) and
  nixpkgs (338 MiB). Touching `nix/flake.nix` printed "cache invalidated: files newer than cache:
  …/nix/flake.nix" and renewed the cache. A second load said "Using cached dev shell" [local].
- **Tested, the failure the WIP keeps:** a folder created without git with `use flake ./nix`, then
  `uv init --app`, which ran `git init`. The cache stayed valid until the next re-evaluation. Then
  came "is not tracked by Git", and nix-direnv printed "Evaluating current devShell failed. Falling
  back to previous environment!" [local]. With `path:./nix` the same sequence renewed the cache
  normally [local].
- **gc safety is the same in every variant.** Only the size of the rooted source changes: 4–8 KiB
  with `path:./nix`; the whole tracked repo with `./nix` in git, under Nix 2.34; the whole folder,
  checkpoints included, for a root flake without git.

---

## 6. Python without Nix in the folder, and uv's own defaults

### 6.1 direnv's `layout uv`

- **Fact:** `layout_uv` watches `.python-version pyproject.toml uv.lock`, fails if `uv` or
  `pyproject.toml` is missing, runs `uv sync --frozen "$@"`, then exports `VIRTUAL_ENV` and puts
  `.venv/bin` on `PATH` [direnv-stdlib#L1135-1171]. It is in direnv ≥ 2.38.0. helios has 2.37.1
  from 26.05; unstable has 2.38.2 [lock].
- **Fact:** extra arguments cannot turn `--frozen` into `--locked`. Tested:
  `uv sync --frozen --locked` → "the argument '--frozen' cannot be used with '--locked'" [local].
- **Side note:** direnv's manual says `layout uv` "fails when [uv.lock] is out of date"
  [direnv-man#L278]. [dev-env-python.md §5](dev-env-python.md) tested `--frozen` and found it
  silent. The template's hand-written `--locked` block stays.

### 6.2 `uv init` and git

- **Fact:** with no `--vcs`, `uv init` runs `git init` and writes a `.gitignore` unless the target is
  already inside a repo. If git is missing, it skips this silently [uv-init#L1331-1363]
  [uv-vcs#L33-75].
- **Fact:** `--vcs none` skips it, and `--bare` implies `--vcs none`
  [uv-cli#L3175-3180] [uv-settings-cli#L598]. `--bare` writes only `pyproject.toml`: no README, no
  `src/`, no `.python-version` [uv-cli#L3108-3117]. Tested: `uv init --bare` kept the template's
  `.python-version` (`3.13` → `requires-python = ">=3.13"`) and created no `.git` [local].
- **Fact:** `--vcs none` inside an existing repo changes nothing, because uv never re-initialises a
  repo [uv-init#L1333-1350]. So one welcome text fits both cases.

### 6.3 Can uv alone pin enough? (option 4)

- **Fact:** `required-version` in `pyproject.toml` or `uv.toml` only _checks_ the running uv. "If the
  version of uv does not meet the requirement at runtime, uv will exit with an error"
  [uv-settings#L261-274] [uv-main#L552-558]. It does not install that version.
- **Fact:** a global uv would come from 26.05, which ships uv 0.11.21; unstable ships 0.13.5
  [lock]. uv is not installed globally today [local].
- **Assessment:** without a per-folder flake, the uv binary, and with it the default Python
  patch, float with nix-config's nixpkgs. `uv.lock` and `.python-version` still pin packages and
  the Python minor. C and C++ have no such fallback: the compiler is the shell.

---

## 7. Options compared

| Option                                                  | Setup friction                              | Pinning                                  | CI parity                                   | gc (nix-direnv roots)                           | Nix commands                                | typhon                      | git added later                             |
| ------------------------------------------------------- | ------------------------------------------- | ---------------------------------------- | ------------------------------------------- | ----------------------------------------------- | ------------------------------------------- | --------------------------- | ------------------------------------------- |
| **1b. `nix/` + `path:./nix` (recommended)**             | none; `git init` optional                   | `nix/flake.lock`                         | `nix develop path:./nix` (tested)           | 8 KiB source + nixpkgs                          | `path:./nix` on each; `nix fmt` from `nix/` | same                        | **nothing breaks** (tested)                 |
| 1a. `nix/` + `./nix` (WIP)                              | none without git                            | same                                     | same in a checkout                          | without git like 1b; in git, whole tracked repo | shorter refs; untracked → error             | same                        | **breaks** until `git add nix` (tested)     |
| 2. Root flake, git required (status quo)                | `git init` first; `-N` is enough, no commit | `flake.lock`                             | `nix develop` (tested earlier)              | whole tracked repo                              | best: no ref, `nix fmt` from root           | same                        | n/a; forgetting git copies the whole folder |
| 2'. Root flake, no git                                  | none                                        | same                                     | same                                        | **whole folder** (10 GiB here)                  | `nix fmt` walks `/nix/store`                | same                        | breaks until tracked                        |
| 3. Separate no-git template (`#python-nogit`)           | pick the right one                          | same                                     | needs a second CI file                      | as 1b                                           | two layouts to remember                     | same                        | the no-git variant is 1b anyway             |
| 4. No flake: global uv + `layout uv` (Python only)      | lowest; needs uv in HM and direnv ≥ 2.38    | uv floats with nix-config (0.11 vs 0.13) | setup-uv already Nix-free                   | nothing to root                                 | none                                        | needs uv on typhon          | none                                        |
| 5a. `use flake ~/nix-config#python` devShell            | lowest per folder                           | nix-config's lock, all projects at once  | none: the path exists only on your machines | nix-config source                               | in nix-config                               | works if both hosts have it | none                                        |
| 5b. `use nix` / `nix shell nixpkgs#uv`                  | low                                         | registry-pinned 26.05; no project lock   | none                                        | rooted by nix-direnv                            | none                                        | differs per host (registry) | none                                        |
| 5c. Root flake with `?dir=` or a `builtins.path` filter | —                                           | —                                        | —                                           | —                                               | —                                           | —                           | **does not work** (§3.1)                    |

Sources for the cells: §3–§6; 5a and 5b as already judged in [dev-env.md §4.3](dev-env.md) and
[dev-env.md §5](dev-env.md); option 2's CI in [dev-env-cpp.md §10](dev-env-cpp.md).

- **Assessment, 1b over 1a:** same files, one word longer. It removes the only failure mode left
  and the git-mode copy of the whole repo.
- **Assessment, 1b over 2:** you lose `nix develop` and `nix fmt` without arguments. You gain:
  no ordering rule, no "not tracked" class of errors, and a store copy that never depends on what
  else sits in the folder. In a git repo with big tracked files, it also avoids the copy (2.34) or
  the full hash (2.35+) on every evaluation.
- **Assessment, 1b over 3:** 1b already works with and without git, so a second template would be
  a copy of it.
- **Assessment, 1b over 4:** 4 is viable for a Python-only scratch folder. But it needs uv in Home
  Manager and direnv 2.38 (26.11), it loses the per-folder uv pin, and it cannot serve C or C++.
  With 1b, a per-folder flake costs one 8 KiB copy and a cached shell, so 4 saves nothing worth
  a second mechanism.
- **Assessment, 1b over 5a/5b:** both drop the per-project lock, and CI cannot reproduce them.
  dev-env.md §4.3 still applies.

---

## 8. Failure modes left in the recommended design

- **`nix/` not committed when you push.** CI fails with a missing path, which is loud and obvious.
  `git add -A` covers it.
- **`nix fmt` from the project root** fails with "could not find a flake.nix file" (no git) or
  "is not part of a flake" (git). Run it in `nix/`. In git, `nix/` must also be tracked, because
  `nix fmt` uses `.` and not `path:` (§4.2).
- **A flake that reads project files.** Only `nix/` is in the flake's source, so `../anything` is
  outside it. Tested: `builtins.readFile ../.python-version` → "access to absolute path
  '/nix/store/.python-version' is forbidden in pure evaluation mode" under `path:./nix`. It worked
  only under `./nix` in git with the file tracked [local]. Neither template reads a project file.
  The nixpkgs-Python runner-up in [dev-env-python.md §9.4](dev-env-python.md) does (§10.4).
- **A `result` link** from `nix build path:./nix` lands in the current directory, not in `nix/`.
  The template's `.gitignore` already lists `result`.

---

## 9. What was tested (helios, aarch64-darwin, Nix 2.34.9+1, direnv 2.37.1, nix-direnv 3.1.2)

All runs were in the scratchpad with `XDG_DATA_HOME`, `UV_CACHE_DIR` and `UV_PYTHON_INSTALL_DIR`
redirected there. Templates came from the uncommitted WIP (staged moves visible to
`nix flake init -t /Users/ety/nix-config#…`). nixpkgs-unstable locked first at `df1e6651c16c`, then
`f9887a8a434b` (2026-11-02), with uv 0.13.5 and nixfmt-tree 2.6.0 [local].

| Command                                                                                                                                                                        | Outcome                                                                                                   |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `nix flake metadata --json path:<dir>`, root flake + 64 MiB file listed in `.gitignore`                                                                                        | 64 MiB store path                                                                                         |
| same, flake in `nix/`                                                                                                                                                          | 4 KiB                                                                                                     |
| `.?dir=nix` / `path:.?dir=nix`, no git                                                                                                                                         | "could not find a flake.nix file" / 64 MiB                                                                |
| git repo, `nix/flake.nix` untracked, `./nix`                                                                                                                                   | "Path 'nix/flake.nix' … is not tracked by Git"                                                            |
| same, `path:./nix`                                                                                                                                                             | ok, same 4 KiB store path as without git                                                                  |
| `git add -N nix/flake.nix`, no commits, `./nix`                                                                                                                                | ok; store path 64 MiB (tracked `junk.bin` included)                                                       |
| `nix flake archive --json` `./nix` vs `path:./nix`, tracked 64 MiB file                                                                                                        | 64 MiB vs 4 KiB                                                                                           |
| `nix flake init -t …#python`, no git                                                                                                                                           | 11 "wrote" lines incl. `nix/flake.nix`; welcomeText shown                                                 |
| `direnv allow`; first load                                                                                                                                                     | `nix/flake.lock` created; "Renewed cache"; uv 0.13.5, `UV_MANAGED_PYTHON=1`                               |
| `uv init --bare`; `uv add --dev ruff basedpyright pytest`; one test                                                                                                            | no `.git`; `ruff format --check`, `ruff check`, `basedpyright` (0 errors), `pytest` pass; CPython 3.13.17 |
| `uv init --app` (no `--vcs`) in a no-git folder, `use flake ./nix`, then re-evaluate                                                                                           | `.git` created; "not tracked by Git"; nix-direnv falls back                                               |
| same folder, `.envrc` → `use flake path:./nix`                                                                                                                                 | "Renewed cache"; `nix develop path:./nix -c uv --version` ok                                              |
| `touch nix/flake.nix` under `path:./nix`                                                                                                                                       | "cache invalidated: files newer than cache: …/nix/flake.nix"                                              |
| `nix flake update --flake ./nix` (no git) and `--flake path:./nix` (git, untracked)                                                                                            | lock updated `df1e665` → `f9887a8`                                                                        |
| `nix fmt` from the project root, no git / git                                                                                                                                  | "could not find a flake.nix file" / "is not part of a flake"                                              |
| `nix fmt` in `nix/`, no git, stock `nixfmt-tree`                                                                                                                               | "tree root: /nix/store"; 59 s; "formatting failures detected"; file not formatted                         |
| same with `settings.tree-root-file = "flake.nix"`, no git and git                                                                                                              | "tree root: …/nix"; formats `nix/*.nix` only                                                              |
| that `flake.nix` through `nixfmt --check`, `statix check`, `deadnix --fail`                                                                                                    | all pass                                                                                                  |
| `nix flake init -t …#cpp`, no git; `direnv allow`; `cmake --workflow --preset debug`; `./build/debug/app`                                                                      | 1/1 tests; `2 + 3 = 5`                                                                                    |
| cpp: commit, fresh clone, `env -i` `nix develop ./nix -c` for each CI step                                                                                                     | `ci` workflow 1/1 under ASan/UBSan; clang-format ok; clang-tidy ok                                        |
| same, `nix develop path:./nix -c cmake --workflow --preset ci`                                                                                                                 | pass                                                                                                      |
| `nix flake check --no-build --all-systems path:./nix` (python, cpp)                                                                                                            | both systems evaluate                                                                                     |
| `builtins.readFile ../.python-version` from `nix/flake.nix`                                                                                                                    | forbidden under `path:./nix` (git or not); ok under `./nix` in git                                        |
| recommended design end to end: no git → `uv init --bare` → checks → `nix fmt` in `nix/` → `git init` → reload → commit → fresh clone → `direnv allow` → `ruff check`, `pytest` | all pass; no error at any step                                                                            |

**Not tested:** anything on Linux (typhon, `ubuntu-latest`); the workflows on GitHub; Nix 2.35's
lazy hashing (read from source and release notes only); the root-flake-without-git `nix fmt` store
walk (same code path, not run); interactive direnv (used `direnv exec`); VS Code.

---

## 10. Change list

### 10.1 Templates

1. **Keep** the staged moves `templates/{python,cpp}/flake.nix` → `templates/{python,cpp}/nix/flake.nix`.
2. **`templates/python/.envrc` and `templates/cpp/.envrc`:** replace the WIP's first three lines with:

   ```bash
   # The flake is in nix/ and loaded as a path: flake, so Nix copies only that
   # folder into /nix/store, with or without git, tracked or not.
   use flake path:./nix
   ```

3. **`templates/cpp/.github/workflows/ci.yml`:** `nix develop ./nix -c` → `nix develop path:./nix -c`
   on all three `run:` lines. (`./nix` also works in a checkout. One spelling everywhere is the
   reason, plus no whole-repo copy under Nix 2.34.) `templates/python/.github/workflows/ci.yml` is
   unchanged: it has no Nix.
4. **`templates/{python,cpp}/nix/flake.nix`:** replace `formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);`
   with (verified with nixfmt, statix and deadnix):

   ```nix
         # Outside git, treefmt would take its config's /nix/store folder as the
         # tree root and walk the whole store. Root it at this folder; run `nix fmt`
         # from nix/.
         formatter = forAllSystems (
           pkgs: pkgs.nixfmt-tree.override { settings.tree-root-file = "flake.nix"; }
         );
   ```

### 10.2 `modules/flake/templates.nix`: new `welcomeText`

`description` stays the same. Python:

````nix
    welcomeText = ''
      # Python project

      Next steps (git is optional: the flake is in `nix/`):

      ```sh
      direnv allow                   # loads uv from nix/flake.nix
      uv init --app --vcs none       # or --lib; or --bare for pyproject.toml only
      uv add --dev ruff basedpyright pytest
      ```

      `.python-version` sets the Python version for uv here and in CI.
      Nix commands take `path:./nix`: `nix flake update --flake path:./nix`.
    '';
````

C and C++:

````nix
    welcomeText = ''
      # C and C++ project

      Next steps (git is optional: the flake is in `nix/`):

      ```sh
      direnv allow                     # loads clang, CMake, Ninja, clangd from nix/flake.nix
      cmake --workflow --preset debug  # configure, build, test
      ./build/debug/app
      ```

      Rename `app` in `CMakeLists.txt`. After `nix flake update --flake path:./nix`,
      run `cmake --fresh --preset debug`: build dirs cache the old store paths.
    '';
````

### 10.3 `docs/research/dev-env.md`

- **Intro list:** add "No git: [dev-env-no-git.md](dev-env-no-git.md)".
- **§1 TL;DR:**
  - first bullet: "its own small, plain `flake.nix`" → "`nix/flake.nix`, loaded by
    `use flake path:./nix`".
  - the "Gotcha found: run `git init` before `nix flake init`" bullet → "**No git needed.** The
    flake sits in `nix/` and loads as `path:./nix`, which copies only that folder, with or without
    git (dev-env-no-git.md)."
- **§4.1 last bullet:** replace "use `git init && nix flake init`" with: `git init` is optional. In
  a repo, init stages its files with `-N`, and `path:./nix` does not need that either.
- **§5 "Update cadence":** `nix flake update` → `nix flake update --flake path:./nix`.
- **§6 second Fact:** the watched files are `nix/flake.nix` and `nix/flake.lock`: nix-direnv
  watches the directory the ref names [nd-direnvrc#L276-298].
- **§7 "When Nix in CI wins":** `nix develop -c uv run pytest` → `nix develop path:./nix -c uv run pytest`.
- **§8 table, first row:** "Update with" → `nix flake update --flake path:./nix`.
- **§9 table, last row** (`nix flake new` + `uv init` → "not tracked"): add "(root flake; gone with
  `path:./nix`, dev-env-no-git.md §5)".
- **§10, row features.md L362-364:** "with one precondition: `git init` first" → "no precondition
  since dev-env-no-git.md".

### 10.4 `docs/research/dev-env-python.md`

- **§5:** `use flake` → `use flake path:./nix`. Add: `layout uv` cannot take `--locked`
  (dev-env-no-git.md §6.1).
- **§6, treefmt bullet:** `nix fmt` runs from `nix/`, with the `tree-root-file` override
  (dev-env-no-git.md §4.3).
- **§8 table, "Python patch" row:** `nix flake update` → `nix flake update --flake path:./nix`.
- **§9.1:** new `welcomeText` (§10.2). The path becomes `templates/python/nix/flake.nix`, with the
  new `formatter`. The `.envrc` block gets the three new lines.
- **§9.3:** drop `git init` as a required first step; keep it as an optional line. Use
  `uv init --app --vcs none`, and `uv init --bare` for notebook or data folders. Replace "Why `git
init` first" with: the failure came from the root flake; with `path:./nix`, git can come at any
  time (tested, dev-env-no-git.md §5). Add `nix fmt` from `nix/`.
- **§9.4 (runner-up flake):** it cannot `readFile ./.python-version` from `nix/`; `../` is outside
  the `path:` source (tested). Hard-code the attribute (`python = pkgs.python313;`), keep it in step
  with `.python-version` by hand, and drop the advice to `watch_file .python-version` before
  `use flake`.
- **§9.5 (migration):** the root `flake.nix` no longer collides with the template's `nix/flake.nix`.
  After `nix flake init`, delete the old `flake.nix`, `flake.lock` (`git rm` in a repo) and
  `.envrc.old`. Moving `.envrc` aside first is still needed, because init refuses to overwrite it.
- **§10:** add "no git, `path:./nix`: see dev-env-no-git.md §9".

### 10.5 `docs/research/dev-env-cpp.md`

- **§1 TL;DR, CI bullet:** `nix develop -c …` → `nix develop path:./nix -c …`.
- **§1 TL;DR, sharp-edge bullet:** `nix flake update` → `nix flake update --flake path:./nix`.
- **§5.1:** `use flake path:./nix`. nix-direnv watches `nix/flake.nix` and `nix/flake.lock`.
- **§7:** the same CI change.
- **§8:** in the table and the bold line, `nix flake update` → `nix flake update --flake path:./nix`.
- **§9.1:** new `welcomeText` (§10.2). The path becomes `templates/cpp/nix/flake.nix`, with the new
  `formatter`. Update the `.envrc` block, and `ci.yml` with `path:./nix`.
- **§9.2:** `nix fmt` in the project runs from `nix/`.
- **§9.3:** `git init` becomes optional, and the "see dev-env-python.md §9.3" reason goes.
- **§9.5:** "`buildInputs` in `nix/flake.nix`".

### 10.6 Elsewhere

- **README:** no change; it does not mention the templates.
- **ADR: not warranted**, by the bar in [dev-env.md §11](dev-env.md). It is not hard to reverse
  (one project or one template edit), and the `.envrc` comment explains the layout where you see it.
- **Your NLP folder** (outside this repo): change its `use flake ./nix` to `use flake path:./nix`,
  and its comment to the one in §10.1. It works today because there is no git; this keeps it
  working if you ever run `git init` there.

---

## 11. Sources

Local: [local] helios, 2026-11-03; every run in §9; this repo @ `99f4655` plus the uncommitted WIP;
`~/Documents/master/semester-3/natural-language-processing` (read-only: listing and `.envrc`).
[lock] `nix eval --inputs-from /Users/ety/nix-config`: `nix` 2.34.9+1 (26.05) and 2.34.9
(unstable); `nixVersions.latest` 2.35.3 (both); direnv 2.37.1 and 2.38.2; uv 0.11.21 (26.05). The
test projects locked nixpkgs-unstable @ `df1e6651c16c` and then @ `f9887a8a434b` (uv 0.13.5).

Nix 2.34.9 (`5fb7eb7d64ba7b78819aa3ac6a7fdd21354910fc`), under
https://github.com/NixOS/nix/blob/5fb7eb7d64ba7b78819aa3ac6a7fdd21354910fc/

- [nix-path] src/libfetchers/path.cc (L141-181; copy at L156-162)
- [nix-archive] src/libutil/archive.cc (L39)
- [nix-flakeref] src/libflake/flakeref.cc (L101-215; search-up L143-166; `.git` → `git+file` with
  `dir` L171-198)
- [nix-flakeref-u] src/libflake/flakeref.cc (L245-262, relative `path:`/`git+file:` URLs)
- [nix-flake-get] src/libflake/flake.cc (L368-406)
- [nix-paths] src/libexpr/paths.cc (L23-44, `FetchMode::Copy`)
- [nix-git] src/libfetchers/git.cc (L472-475 `getSourcePath`; L768-784 "not tracked by Git")
- [nix-git-utils] src/libfetchers/git-utils.cc (L539-570)
- [nix-init] src/nix/flake.cc (L961-973)
- [nix-formatter] src/nix/formatter.cc (L74-110) · [nix-fmt-md] src/nix/formatter-run.md (L11-13)

Nix 2.35.4 (`21286d605815196c3fff1960550ab08700fc4e6f`) and master

- [rl-2.35] https://github.com/NixOS/nix/blob/21286d605815196c3fff1960550ab08700fc4e6f/doc/manual/source/release-notes/rl-2.35.md (L1-30)
- [nix-paths-2.35] https://github.com/NixOS/nix/blob/21286d605815196c3fff1960550ab08700fc4e6f/src/libexpr/paths.cc (L64-89, `FetchMode::DryRun`)
- [nix-15711] https://github.com/NixOS/nix/commit/891ef140b856 ("Don't copy flakes to the store
  unnecessarily", PR #15711, 2026-04-25)
- [nix-path-master] https://github.com/NixOS/nix/blob/e8962d01875f41b781ddd9edeac904fafd285b0b/src/libfetchers/path.cc (L142-180)
- [rl-next-hg] https://github.com/NixOS/nix/blob/e8962d01875f41b781ddd9edeac904fafd285b0b/doc/manual/rl-next/local-repo-detection.md (L5-8)

direnv

- [nd-direnvrc] https://github.com/nix-community/nix-direnv/blob/d0ccbf8cb4b628a7a2e49c655d75fda7f7e4437c/direnvrc
  (3.1.2: L271-392; L276-298, L343-363)
- [nd-direnvrc-master] https://github.com/nix-community/nix-direnv/blob/26a92d274b7fbddfb5668bf2c2e160762818e50c/direnvrc
  (3.2.0+: L277-409; L283-304, L366-371)
- [direnv-stdlib] https://github.com/direnv/direnv/blob/3d0b4ae1ed83064a10ada052949596e7463a8768/stdlib.sh (L1135-1171)
- [direnv-man] https://github.com/direnv/direnv/blob/3d0b4ae1ed83064a10ada052949596e7463a8768/man/direnv-stdlib.1.md (L276-278)

uv (`9b11efe914e01b9dfaa53beebc2180f37dafb19b`, 2026-11-02; latest release 0.13.6), under
https://github.com/astral-sh/uv/blob/9b11efe914e01b9dfaa53beebc2180f37dafb19b/

- [uv-cli] crates/uv-cli/src/lib.rs (L3108-3117 `--bare`; L3175-3180 `--vcs`)
- [uv-settings-cli] crates/uv-cli/src/settings.rs (L598)
- [uv-init] crates/uv-project-commands/src/init.rs (L1331-1363)
- [uv-vcs] crates/uv-configuration/src/vcs.rs (L33-75)
- [uv-settings] crates/uv-settings/src/settings.rs (L261-274)
- [uv-main] crates/uv/src/lib.rs (L552-558)

treefmt v2.6.0 (`088c52d4e4ec34bde6a4b00738ac6db5de76c347`), under
https://github.com/numtide/treefmt/blob/088c52d4e4ec34bde6a4b00738ac6db5de76c347/

- [tf-config] config/config.go (L124-128, L171-173, L281-379)
- [tf-root] cmd/root.go (L82-84, L136-140)

nixpkgs-unstable (`f9887a8a434bfba06e20dfc77bc8e0628266af84`), under
https://github.com/NixOS/nixpkgs/blob/f9887a8a434bfba06e20dfc77bc8e0628266af84/

- [nixfmt-tree] pkgs/by-name/ni/nixfmt-tree/package.nix (L10, L23-46)
- [tf-wrapper] pkgs/by-name/tr/treefmt/modules/wrapper.nix (L40-43)
