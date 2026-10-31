# Per-project dev environments: the pattern

Research date: 2026-10-30. Method: each candidate's own repo or docs were read at the commits in §14,
and claims were followed to the code that owns them (Nix's `flake init`/`flake check`, flake-parts,
import-tree, nix-direnv, direnv's stdlib, devenv, GitHub's docs). Package versions come from this
flake's locked inputs [lock]. The pattern was built in a throwaway copy of this repo and tested end
to end on helios in the scratchpad (§9). Nothing in the config or in your projects was changed
[local]. Stars and push dates come from `gh api repos/<owner>/<repo>` on 2026-10-30 [gh-meta].
"Fact" statements carry a citation; **Assessment** marks my judgement. Familiarity was not used as a
reason for any pick.

This file is the language-independent half. Each language has its own file with its toolchain
choice and a worked template:

- **Python:** [dev-env-python.md](dev-env-python.md), template `templates/python/`.
- **C and C++:** [dev-env-cpp.md](dev-env-cpp.md), template `templates/cpp/`.
- Add `dev-env-<lang>.md` for each new language, built on this pattern, and list it here.

---

## 1. TL;DR

- **Pattern: a flake `templates` output in nix-config. Each project gets its own small, plain
  `flake.nix` plus `.envrc`.** Nix supplies the tools, usually just the language's own package
  manager (for Python: `uv`). That manager supplies the language and its dependencies from its own
  lockfile. direnv with nix-direnv activates the shell when you `cd` in.
- **Where it goes:** `modules/flake/templates.nix` (one file for all templates) plus
  `templates/<lang>/` at the repo root, outside `modules/`, so import-tree never sees it (§4.2).
- **The project flake** is plain (no flake-parts), on `nixpkgs-unstable` with its own lock, for
  `aarch64-darwin` and `x86_64-linux`. It does not follow the system's nixpkgs (§5).
- **CI:** when the shell only carries the language's package manager, use that manager's own
  setup action on `ubuntu-latest`, without Nix. Nix in CI pays off once the shell carries other
  tools the tests run (§7). Skip macOS runners: they cost about 10× more per minute [gh-prices].
- **Gotcha found:** run `git init` before `nix flake init`. Otherwise the files the template
  writes are untracked, and evaluation fails (tested). A second gotcha, the global `.envrc`
  ignore hiding `templates/python/.envrc`, is gone: the global ignores were removed from
  `git.nix` after this research (§12).
- **Alternatives:** devenv when a project needs services (PostgreSQL, Redis); devshell, flox and
  devbox add a layer without a gain (§4). The old `c`/`python` devShells are already gone
  (`9f2a720`). **No ADR**: each project can undo this on its own (§11).

---

## 2. How you work today (evidence)

All read-only on 2026-10-30 [local]; secret values in `.envrc` files were not read.

- **pixi is used heavily (314 history lines) for one ROS 2 project:** RoboStack channels, `compilers`,
  `boost` and conda packages, plus a Nix flake for LaTeX that runs `pixi shell-hook` [local].
- **Secrets live in `.envrc`:** `engineering-AI-systems/.envrc` exports two tokens [local]. This
  was why `.envrc` was globally git-ignored; that list has since been removed from `git.nix`, and
  the repo's own `.gitignore` covers its `.envrc`.
- **Already gone:** the `c`/`python` devShells in nix-config were dropped in `9f2a720`
  ("never used") [local].
- **Python specifics** (five dev-templates projects, no lockfile, a team repo): see
  [dev-env-python.md §2](dev-env-python.md).

---

## 3. Candidates and activity

| Candidate                        | Stars | Last push  | Latest                    | Role                           |
| -------------------------------- | ----- | ---------- | ------------------------- | ------------------------------ |
| flake `templates` (Nix built-in) | n/a   | n/a        | Nix 2.34.9 local          | delivery                       |
| hercules-ci/flake-parts          | 1.5k  | 2026-10-01 | locked `024633c`          | `flake.templates` in this repo |
| nix-community/nix-direnv         | 2.8k  | 2026-10-25 | 3.2.0 (26.05 has 3.1.2)   | cached `use flake`             |
| direnv/direnv                    | 15.5k | 2026-10-26 | 2.38.2 (26.05 has 2.37.1) | `.envrc`                       |
| cachix/devenv                    | 7.8k  | 2026-10-30 | v2.4.0 (26.05 has 2.1.2)  | alternative                    |
| numtide/devshell                 | 1.6k  | 2026-10-15 | n/a                       | alternative                    |
| flox/flox                        | 4.2k  | 2026-10-30 | v1.19.3                   | alternative                    |
| jetify-com/devbox                | 12.4k | 2026-10-29 | 0.19.0                    | alternative                    |
| the-nix-way/dev-templates        | 2.4k  | 2026-10-13 | n/a                       | your current source            |
| cachix/install-nix-action        | 708   | 2026-10-27 | v31.11.3                  | CI (alternative)               |

Sources: [gh-meta] [lock]. A search for newer Nix dev-env tools created since 2025-06 found
nothing credible above 200 stars [gh-meta].

Python-specific candidates (uv, uv2nix, pixi, ruff, basedpyright, ty, setup-uv) are in
[dev-env-python.md §3](dev-env-python.md).

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
  by nix-config's check, so each language doc tests its template separately.
- **Fact:** `nix flake new -t … <dir>` does the same into a new directory without `git init`
  [local]. **Assessment:** use `git init && nix flake init`; [dev-env-python.md §9.3](dev-env-python.md) shows why.

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
- **`mkShellNoCC`** when the language manager brings its own toolchain (Python: uv). Python comes from uv, so the shell needs no compiler. An sdist C extension
  (markupsafe built with `--no-binary-package`) compiled fine with Xcode's `/usr/bin/cc`.
  `sysconfig` `CC` is `cc` [local]. On typhon there is no system compiler; see [dev-env-python.md §4.4](dev-env-python.md).
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
- **Fact:** direnv carries on after a failing command in `.envrc`. With a stale lock the env still
  loaded and the uv error was printed [local].
- **Secrets:** move `export TOKEN=…` lines into `.env` (`KEY=value`, gitignored).
  `dotenv_if_exists` loads it. The committed `.envrc` then holds no secrets.
- **Language specifics** (what the `.envrc` runs after `use flake`): Python's is in
  [dev-env-python.md §5](dev-env-python.md).

---

## 7. CI

- **Rule:** when the dev shell holds only the language's package manager, CI uses that
  manager's own setup action and no Nix. Python: `astral-sh/setup-uv`
  ([dev-env-python.md §7](dev-env-python.md)).
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

## 8. What is pinned where, and how updates flow

| What                   | Pinned by                           | Update with                           |
| ---------------------- | ----------------------------------- | ------------------------------------- |
| uv binary, nixfmt-tree | `flake.lock` (nixpkgs-unstable rev) | `nix flake update`                    |
| CI actions             | exact tags in `ci.yml`              | edit (or Dependabot `github-actions`) |

- Language rows (interpreter, packages, tool config): [dev-env-python.md §8](dev-env-python.md).

---

## 9. What was tested (helios, aarch64-darwin, Nix 2.34.9, direnv 2.37.1)

All runs were in the scratchpad, with uv's Python and cache dirs redirected there
(`UV_PYTHON_INSTALL_DIR`, `UV_CACHE_DIR`) [local]. The global git ignores were still in place for
these runs.

| Command                                                                              | Outcome                                                         |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------- |
| `git clone ~/nix-config` → copy; add `templates.nix` + `templates/python`; `git add` | `.envrc` silently missing (global ignore)                       |
| `nix flake init -t <copy>#python` before `git add -f .envrc`                         | 6 files written, no `.envrc`, no warning                        |
| same after `git add -f templates/python/.envrc`                                      | 7 files written and staged intent-to-add; welcomeText rendered  |
| second module defining `flake.templates.c`                                           | error "defined multiple times while it's expected to be unique" |
| `nix flake check --no-build` on the copy                                             | "checking template 'templates.python'… all checks passed"       |
| `nix fmt` on the copy                                                                | 0 files changed                                                 |
| `direnv allow` + `direnv exec . …` (first load)                                      | shell built; then "Using cached dev shell", 0.1 s               |
| `touch uv.lock`, reload                                                              | "Using cached dev shell" (no Nix re-eval)                       |
| `nix flake new` + `uv init` (no prior `git init`)                                    | "Path 'flake.nix' … is not tracked by Git"                      |

Python-specific runs: [dev-env-python.md §10](dev-env-python.md).

---

## 10. Review of earlier verdicts

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

## 11. When the alternatives win, more languages, and the ADR question

- **devenv:** the project needs services or processes (PostgreSQL, Redis, workers), or several
  languages with managed native libraries on NixOS.
- **Nix in CI:** the dev shell carries non-Python tools the tests run.
- **`c` template:** add `flake.templates.c` to the same `templates.nix` and a `templates/c/` when
  the next C/C++ project starts. That is `mkShell` (it needs a compiler), clang-tools, cmake and
  ninja, as in the deleted shell. Do not add it before then.
- **ADR: not warranted.** The bar is all three of: hard to reverse, surprising without context,
  and a real trade-off. This fails the first: each project owns its flake and can switch
  variants, or drop Nix, alone. The comment in `templates.nix` and this document cover the "why
  is Python not from Nix?" question. Revisit if many projects come to depend on a shared
  mechanism (e.g. a `nix-config` input).
- **Python runner-ups** (nixpkgs Python, pixi, uv2nix): [dev-env-python.md §11](dev-env-python.md).

---

## 12. Side findings (outside the template)

- **Global ignores: removed** after this research. `git.nix` no longer sets
  `programs.git.ignores`, so each repo's `.gitignore` is the whole list and `git add -f` is not
  needed for the template. Secrets go in `.env`, which the template's `.gitignore` covers.
  Existing repos were checked: `engineering-AI-systems` already ignores its token-holding
  `.envrc` itself; `.direnv/` was added to its `.gitignore` and `spotify_to_ytmusic`'s, and to
  `.git/info/exclude` in the team repo `silcrst-team`.
- **nix-config's `nixpkgs-unstable` input tracks `nixos-unstable`.** That branch is gated on NixOS
  tests, not on the darwin jobs that gate `nixpkgs-unstable` [channels.nix#L27-40]
  [release.nix#L164-212]. **Assessment:** helios takes `claude-code` and `opencode` from it, so a
  darwin cache miss is possible right after a bump. Not observed; check before changing.
- **Dependabot now updates `flake.lock` (public repos) and `uv.lock`** [dbot#L33-34]
  [dbot#L58-61] [dbot#L174-178]. This is a possible alternative to `update-flake-lock`
  (best-of-nix §4.3). Not tested.

---

## 13. Limitations (not verified)

- **Not run:**
  - `nix flake init -t github:Ety0011/nix-config#python` (needs the template pushed);
  - Dependabot `nix` updates;
  - devenv itself.
- **Interactive direnv not used.** Shell hook reloads were not exercised. `direnv exec` evaluates
  the same `.envrc` and the same watch list.
- Python-specific limitations: [dev-env-python.md §13](dev-env-python.md).

---

## 14. Sources

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

Alternatives

- [devenv-readme] https://github.com/cachix/devenv/blob/0d6c556e5f862c14a75a543e2ee4fdb7acc005ad/README.md (L24-60, L131-156)
- [devenv-py] …/src/modules/languages/python/default.nix (L10-12, L342-350, L412-433, L500)
- [devenv-py-docs] …/docs/src/content/docs/languages/python.md (L14-64, L134-184, L256-261)
- [devenv-flakes] …/docs/src/content/docs/guides/using-with-flakes.md (L17-33)
- [devshell] https://github.com/numtide/devshell/blob/9e29c63dde99a2d80c94b3d024c9768c01544558/README.md (L1-3)
- [flox] https://github.com/flox/flox/blob/da039c11477e210045a7472b15933b55947f9bd1/README.md (L42, L90)
- [devbox] https://github.com/jetify-com/devbox/blob/dc599b1c59dd3e8de890110d74ff6951b96f3f75/README.md (L27-31, L57)
- [dt-python] https://github.com/the-nix-way/dev-templates/blob/9ffac48bbda3ba44e58e250d9a57d4520ce55401/python/flake.nix (L1-101)

CI

- [inix] https://github.com/cachix/install-nix-action/blob/75c75c31ebece974e48ebc36b4ad125bd97bd97b/README.md (L9, L38-52, L73-87)
- [mnc] https://github.com/DeterminateSystems/magic-nix-cache-action/blob/f69a2d3e148e90223fe63ab6e3f6331f2e7e33dc/README.md (L1-30)
- [gh-prices] https://github.com/github/docs/blob/9860344c45e8c0a43970665e3b219a9d0f56c0dd/data/reusables/billing/actions-standard-runner-prices.md (L1-9)
- [gh-billing] …/content/billing/concepts/product-billing/github-actions.md (L127-130)
- [dbot] …/data/reusables/dependabot/supported-package-managers.md (L33-34, L58-61, L174-178) ·
  feature flags `data/features/dependabot-{nix,uv}-support.yml` (`fpt: '*'`)
