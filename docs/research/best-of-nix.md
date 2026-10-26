# Best of Nix: what to adopt for this config

Research date: 2026-10-26. Starting point: the best-of-nix ranked list at commit `28f7f13`
[bon]. Every pick was then checked against its own repo or docs. Sources are pinned to commits
where possible (see §10). "Fact" statements carry a citation; **Assessment** marks my judgement.
Stars and last-push dates come from `gh api repos/<owner>/<repo>` on 2026-10-26 [gh-meta].

---

## 1. TL;DR

- **Strongly recommended (adopt soon):**
  1. **nh** for rebuilds, diffs and search. It is in nixpkgs 26.05 (4.4.2), comes with a
     Home Manager module, supports nix-darwin, and bundles nix-output-monitor and dix diffs
     [nixpkgs-nh] [hm-nh] [nh-readme].
  2. **statix + deadnix** as treefmt programs. No new flake input, and `nix flake check`
     already runs treefmt [tfn-statix] [tfn-deadnix] [tfn-flakecheck].
  3. **nix-index-database + comma.** One flake input and one Home Manager import give you
     `command-not-found` and `, <cmd>` [nid-readme].
  4. **Fix Spotlight for Home Manager apps with `targets.darwin.copyApps`.** helios has
     `home.stateVersion = "24.11"`, so HM still symlinks apps [hm-linkapps] [hm-copyapps].
     mac-app-util is no longer needed.
  5. **Take fast-moving CLIs from `pkgs.unstable`.** `claude-code` is 2.1.223 on 26.05 and
     2.1.308 on unstable [nixpkgs-claude]. The overlay already exists.
- **Keep what you have:** nixd (not nil), nixfmt, treefmt, nix-direnv, plain `mkShell`
  devShells, and upstream Nix managed by nix-darwin (not Determinate, not Lix).
- **Useful, each with a trigger:** for typhon's install, disko + nixos-anywhere + nixpkgs'
  built-in `hardware.facter`. sops-nix for the first real secret. GitHub Actions CI
  (`cachix/install-nix-action` + `update-flake-lock`) once helios runs the new config.
  nix-homebrew for the next fresh Mac. llm-agents.nix if unstable lags. Also nixos-hardware,
  srvos, devenv, stylix and the nix-darwin linux-builder.
- **Skipped:** Determinate Nix, Lix, agenix/ragenix, deploy-rs/colmena/comin (for now),
  impermanence, lanzaboote, hjem, nixvim/nvf, magic-nix-cache, attic, Renovate,
  nixos-generators (archived) and nixos-facter-modules (archived, upstreamed).
- **Two config gotchas found along the way** (§7). On darwin `@wheel` contains only `root`,
  so `ety` is not a trusted Nix user [local]. And helios still runs the previous config,
  revision `8088b5e-dirty` [local].

---

## 2. How picks were judged

- **Fit with the dendritic layout.** A pick is cheap when it lands as one Feature file
  writing into `flake.modules.<class>.base`, or as a line in an existing Feature. External
  modules are imported inside the Feature, so each one is imported along exactly one path
  (ADR 0001):

  ```nix
  { inputs, ... }:
  {
    flake.modules.homeManager.base = {
      imports = [ inputs.nix-index-database.homeModules.default ];
      programs.nix-index-database.comma.enable = true;
    };
  }
  ```

- **Darwin first.** helios is the only live Host. Linux-only tools wait for typhon.
- **New flake inputs cost something:** lockfile churn, an extra nixpkgs unless you use
  `follows`, and one more upstream to trust. A package from nixpkgs is preferred over a flake
  input when the two are equivalent.
- **Reversibility.** Anything that changes on-disk state (disk layout, secret format, the Nix
  implementation, Homebrew cleanup) gets an ADR flag in §8.

---

## 3. Strongly recommended

### 3.1 nh (plus nix-output-monitor and dix, bundled)

- **What:** one CLI for `nh darwin switch`, `nh os switch`, `nh home switch`, `nh search` and
  `nh clean` [nh-readme]. `nh darwin` is "a pure-rust reimplementation of the
  `darwin-rebuild` script" that adds build trees and pretty diffs [nh-readme].
- **Bundles:** nixpkgs' `nh` wrapper puts `nix-output-monitor` on its PATH [nixpkgs-nh]. The
  diffs come from the dix crate, which replaced nvd [nh-readme] [dix]. So there is no need to
  install nom, nvd or dix separately.
- **Darwin:** yes. The HM module has `darwinFlake` and a launchd agent for `clean`
  [hm-nh].
- **Maturity:** 3.3k stars, pushed 2026-10-24 [gh-meta]. The stable release is v4.4.2
  (2026-07-28); v4.5.0-beta2 is a pre-release [nh-releases]. nixpkgs 26.05 ships 4.4.2
  [nixpkgs-nh].
- **Where it goes:** `modules/features/nix-tools.nix`, in the `homeManager.base` half:
  `programs.nh = { enable = true; flake = "${config.home.homeDirectory}/nix-config"; };`.
  This sets `NH_FLAKE` [hm-nh], so the per-Class `update` aliases can become
  `nh darwin switch` and `nh os switch`, or be dropped.
- **Gotchas:**
  - Do not enable `programs.nh.clean` while nix-darwin's `nix.gc` is on. The HM module
    already asserts against HM's own `nix.gc` [hm-nh]. **Assessment:** keep the system `nix.gc`.
  - After 4.4.2, nh replaces nom with its built-in "rom" (`NH_NOM` becomes `NH_ROM`)
    [nh-changelog]. Expect that rename when 26.11 lands.
- **Assessment:** this is the biggest day-to-day UX win for the least config. It also gives
  you a closure diff on every switch, which CLAUDE.md asks for by hand today
  (`nix store diff-closures`).

### 3.2 statix + deadnix via treefmt-nix

- **What:** statix lints Nix anti-patterns and can fix some of them. deadnix finds unused
  bindings and arguments [statix-orig] [deadnix].
- **Status:** statix upstream moved to tangled.org. nixpkgs builds the
  `molybdenumsoftware/statix` fork, which was pushed 2026-10-23 [statix-orig] [nixpkgs-statix]
  [gh-meta]. deadnix: 794 stars, pushed 2026-10-03 [gh-meta].
- **Where it goes:** `modules/flake/formatter.nix`:
  `programs.statix.enable = true; programs.deadnix.enable = true;`. treefmt-nix
  has modules for both [tfn-statix] [tfn-deadnix]. `treefmt.flakeCheck` defaults to `true`,
  so `nix flake check` enforces them with no extra wiring [tfn-flakecheck].
- **Darwin:** yes; both are plain CLIs from nixpkgs [local].
- **Gotchas:**
  - treefmt runs `statix fix` and `deadnix --edit`, so both rewrite files [tfn-statix]
    [tfn-deadnix]. Land the first run as its own commit.
  - statix's `repeated_keys` lint (W20) flags repeated attribute paths like `foo.a`, `foo.b`,
    `foo.c` [statix-repeated]. A Feature with three `flake.modules.…` keys (e.g. `zsh.nix`)
    will likely trip it. That repetition is deliberate in the dendritic style. Add it to
    `programs.statix.disabled-lints` [tfn-statix].
  - treefmt-nix also offers `nixf-diagnose` (nixd's static checker) as a program [tfn-programs].
    It is optional.

### 3.3 nix-index-database + comma

- **What:** a weekly prebuilt `nix-index` database, plus modules that wrap `nix-locate`
  and, optionally, comma (`, cowsay` runs a program without installing it) [nid-readme].
- **Darwin:** yes. It ships `darwinModules`, `nixosModules` and `homeModules` [nid-flake].
- **Maturity:** 624 stars. The database is released weekly; the latest tag is
  `2026-10-25-074941` [gh-meta]. comma: 1.8k stars, v2.4.2 [gh-meta].
- **Where it goes:** a new `modules/features/nix-index.nix` with the snippet in §2. Use the
  `homeModules` variant so it works the same on both Hosts. Its shared module already sets
  `programs.nix-index.enable = lib.mkDefault true` [nid-shared].
- **Gotchas:**
  - The database is built from nixos-unstable [nid-readme], so a match can name a package
    that 26.05 lacks or has at another version. This is minor for "which package has this
    binary".
  - Do not also install `nix-index` yourself; it conflicts with the wrapper [nid-readme].
  - Add `inputs.nixpkgs.follows = "nixpkgs"` to the input, as the README does [nid-readme].

### 3.4 Make Home Manager apps visible to Spotlight (`copyApps`)

- **Facts:** HM 26.05 enables `targets.darwin.linkApps` (symlinks) when
  `home.stateVersion` is below 25.11. It enables `targets.darwin.copyApps` ("works with
  Spotlight") at 25.11 and above [hm-linkapps] [hm-copyapps]. helios pins `24.11`, so
  `rectangle` (in `home.packages`) gets symlinked. nix-darwin itself already rsyncs system
  apps into `/Applications/Nix Apps` [nd-apps].
- **Where it goes:** set `targets.darwin.copyApps.enable = true;` and
  `targets.darwin.linkApps.enable = false;` in a darwin-only HM module. Use
  `flake.modules.darwin.base.home-manager.sharedModules`, as `nix-tools.nix` does for its
  alias.
- **Gotcha:** copying into app bundles needs macOS "App Management" permission for your
  terminal. Both nix-darwin and HM check for it and abort with instructions
  [nd-apps] [hm-copyapps].
- **Assessment:** this replaces mac-app-util (455 stars, last push 2026-07-04 [gh-meta]),
  which solved the same Spotlight and Dock problem [mac-app-util]. Do not raise
  `home.stateVersion` to get this; CLAUDE.md forbids it.

### 3.5 `pkgs.unstable` for AI CLIs

- **Facts:** `claude-code` is 2.1.223 in `nixpkgs-26.05-darwin` and 2.1.308 in
  `nixos-unstable`; llm-agents.nix has 2.1.310 [nixpkgs-claude] [llm-agents-cc].
- **Where it goes:** in `modules/users/ety.nix`, change `claude-code` and `opencode` to
  `unstable.claude-code` and `unstable.opencode`. The `unstable` overlay is already in
  `modules/flake/pkgs.nix`.
- **Assessment:** this needs no new input. Move to llm-agents.nix (§4.5) only if unstable
  still lags.

---

## 4. Useful (adopt when the trigger fires)

### 4.1 typhon install: disko + nixos-anywhere + `hardware.facter`

**Trigger:** typhon's hardware is on the desk.

- **disko** declares partitions, LUKS, LVM and filesystems (ext4, btrfs, ZFS, bcachefs). It
  is used with nixos-anywhere or from an installer [disko]. 3.4k stars, v1.13.0 [gh-meta].
- **nixos-anywhere** installs over SSH. It kexecs into an installer if needed, runs disko,
  and installs NixOS. The source can be "any machine with Nix installed". It does not
  support wifi on the target [nxa-readme]. 3.5k stars, 1.13.0 [gh-meta].
- **nixos-facter** writes a JSON hardware report. Its NixOS modules are now in nixpkgs
  (`hardware.facter.reportPath = ./facter.json;`), and the separate `nixos-facter-modules`
  repo is archived [facter] [facter-modules] [nixpkgs-facter]. nixos-anywhere generates the
  report with `--generate-hardware-config nixos-facter ./facter.json` [nxa-quickstart].
- **Where it goes:**
  - Add a flake input `disko` (follows `nixpkgs`).
  - In `modules/hosts/typhon/default.nix`, import `inputs.disko.nixosModules.disko` and a new
    `./_disko.nix`. import-tree skips `/_` paths, so `_disko.nix` must be imported explicitly,
    like `_hardware.nix`.
  - Replace `_hardware.nix` with `{ hardware.facter.reportPath = ./facter.json; }` plus the
    bootloader lines. import-tree ignores `facter.json` (not `.nix`), but it must still be
    `git add`ed.
  - nixos-anywhere needs no input: `nix run github:nix-community/nixos-anywhere -- …`.
- **Gotchas:**
  - helios is `aarch64-darwin`, so it cannot build typhon's `x86_64-linux` closure natively.
    `--build-on auto` "falls back gracefully to remote build" [nxa-ref], so the target builds
    it.
  - `nix flake check` on helios only checks the current system unless you pass
    `--all-systems` [local]. typhon's build check really runs only in CI (§4.3) or on typhon.
  - The disk layout is hard to change later. Decide on encryption, the filesystem and
    whether you want impermanence before running it (ADR, §8).
- **nixos-hardware** (3.3k stars, pushed 2026-10-22 [gh-meta]): add it only if typhon is a
  model it lists (laptops, Framework, etc.). For generic desktops facter covers drivers and
  firmware [facter].

### 4.2 Secrets: sops-nix

**Trigger:** the first real secret, e.g. typhon's user password hash, Syncthing keys or a
wifi PSK.

- **Facts:** it decrypts sops files (YAML/JSON/dotenv/INI/binary) at activation, using age or
  GPG. `ssh-to-age` turns an SSH Ed25519 key into an age key [sops]. It has NixOS, nix-darwin
  and Home Manager modules [sops-flake]. The HM module runs as a launchd agent on darwin
  [sops-hm]. On darwin the user age key goes in
  `~/Library/Application Support/sops/age/keys.txt` [sops]. 3.2k stars, pushed 2026-10-25
  [gh-meta].
- **Compared with agenix:** agenix uses one `.age` file per secret and plain SSH recipients
  [agenix]. It also has darwin and HM modules (launchd on darwin) [agenix-flake]
  [agenix-hm]. 2.5k stars, 0.18.0 [gh-meta]. ragenix is a Rust drop-in for agenix; its last
  tag is `2025.03.09` [ragenix] [gh-meta]. agenix-rekey adds YubiKey and master-identity
  rekeying [bon].
- **Where it goes:** `modules/features/sops.nix` importing `inputs.sops-nix.darwinModules.sops`
  into `darwin.base`, `nixosModules.sops` into `nixos.base`, and `homeManagerModules.sops`
  into `homeManager.base`. Also add `.sops.yaml` and `secrets/` at the repo root.
- **Assessment:** sops-nix, because you used it before, one file holds many secrets, and it
  has more stars and activity. Both tools are mature, and either is fine. The choice is
  sticky (encrypted files and key setup), so write an ADR.

### 4.3 CI: install-nix-action + update-flake-lock (+ flake-checker)

**Trigger:** helios has switched to this config and you want weekly updates that are proven
to build.

- **Facts:**
  - `cachix/install-nix-action` installs upstream Nix on Linux and macOS runners, with flakes
    on by default [inix]. That matches helios, which runs upstream Nix 2.31.5 [local].
  - `DeterminateSystems/nix-installer-action` installs Determinate Nix by default [nia].
  - `update-flake-lock` opens a PR on a cron schedule. A PR opened with the default token
    does not trigger CI; you either close and reopen it or give the action a PAT
    (`GH_TOKEN_FOR_UPDATES`) [uflock].
  - The repo is public [gh-meta], so standard GitHub-hosted runners are free.
- **Where it goes:** `.github/workflows/check.yml` with a matrix of `macos-latest` and
  `ubuntu-latest`, each running `nix flake check`. That covers helios and typhon, plus the
  treefmt check. Then `.github/workflows/update.yml` for update-flake-lock.
- **Optional:** `DeterminateSystems/flake-checker-action` warns when nixpkgs inputs are old
  or not on a supported branch [bon] [flake-checker].
- **Assessment:** skip magic-nix-cache, cachix and attic for now. Two Hosts build in minutes
  from cache.nixos.org. Magic Nix Cache is CI-only [mnc], and attic is a server to run
  yourself [attic].

### 4.4 nix-homebrew

**Trigger:** setting up a fresh Mac, or needing a third-party tap.

- **Facts:** it installs and pins Homebrew itself, can manage taps declaratively
  (`mutableTaps = false`), and can migrate an existing install (`autoMigrate = true`). It
  "does not manage any package installed by it"; that stays with nix-darwin's `homebrew.*`
  [nix-homebrew]. 784 stars, pushed 2026-10-23, no tagged releases [gh-meta].
- **Where it goes:** `modules/features/homebrew.nix`. Note `nix-homebrew.user` is
  User-specific, and taps need `homebrew-core`/`homebrew-cask` as non-flake inputs
  [nix-homebrew].
- **Assessment:** your brew works, you have no taps, and the tap inputs are large repos that
  churn the lockfile. Shrinking the brew list (step 8 in §8) pays off more.

### 4.5 Other triggers

- **srvos** (1k stars [gh-meta]), if typhon is headless. It provides server profiles such as
  `srvos.nixosModules.server` and also has darwin modules [srvos] [srvos-darwin]. It would sit
  in a `server` Role.
- **devenv** (7.8k stars, v2.4.0 [gh-meta]), when a project needs services (PostgreSQL,
  Redis) or a process manager [devenv]. It is per project and does not belong in this repo.
  Plain `mkShell` + nix-direnv stays the default.
- **stylix** (2.5k stars, has a `release-26.05` branch [gh-meta]), when typhon gets a
  desktop. It themes NixOS, HM and nix-darwin apps [stylix]. catppuccin/nix is the
  single-palette alternative [catppuccin].
- **nix-darwin linux-builder** (built in), if you want helios to build Linux closures. It is
  `nix.linux-builder.enable`; its `systems` default to the builder VM's own platform
  [nd-linux-builder]. On Apple Silicon that is `aarch64-linux`; `x86_64-linux` needs extra
  setup.
- **llm-agents.nix** (2.2k stars, packages updated daily [gh-meta] [llm-agents]), if
  `pkgs.unstable` lags for AI CLIs. It is built only against its own nixpkgs-unstable pin.
  Do not set `follows` to a stable branch. Its cache is `cache.numtide.com` [llm-agents].
  Add the substituter in `nix-daemon.nix`, because `ety` is not trusted to accept flake
  `nixConfig` (§7).

---

## 5. Nice to have

- **Touch ID for sudo:** `security.pam.services.sudo_local.touchIdAuth = true;`, optionally
  with `reattach` for tmux [nd-pam]. One line in `darwin-settings.nix`.
- **nixd option completion in VS Code.** nixd supports options for "NixOS/home-manager/
  flake-parts" via `options.<name>.expr` [nixd-readme] [nixd-config]. For example,
  `(builtins.getFlake (toString ./.)).darwinConfigurations.helios.options`.
- **mcp-nixos** (864 stars [gh-meta]): an MCP server for NixOS, HM and nix-darwin options and
  packages. It is in nixpkgs 26.05 (2.4.3) [mcp-nixos] [nixpkgs-mcp]. HM 26.05 has
  `programs.claude-code.mcpServers` [hm-claude], so it could live in a `claude-code` Feature.
- **git-hooks.nix** (875 stars [gh-meta]), with a flake-parts module and `prek` support
  [git-hooks]. It runs treefmt before each commit. **Assessment:** low value until CI exists,
  because `nix flake check` already enforces formatting.
- **nix-search-tv / optnix**: TUI search over packages and options [bon]. `nh search` covers
  most of this.
- **Flake templates.** `the-nix-way/dev-templates` (2.4k stars [gh-meta]) is a good source. A
  `templates` output would let new projects get their own `flake.nix` + `.envrc` instead of
  `nix develop ~/nix-config#python`.
- **nix-vscode-extensions** (399 stars [gh-meta]), only if you decide to manage VS Code with HM
  `programs.vscode`. That is a bigger change than it looks.

---

## 6. Considered and skipped

- **Determinate Nix:** on nix-darwin you must import its module and set
  `determinateNix.enable = true`, otherwise "Determinate Nix does not work properly"
  [det]. That hands Nix configuration (your `nix-daemon.nix`) over to Determinate. There is
  no concrete gain for this user.
- **Lix:** an alternative Nix implementation [lix]. It would swap the evaluator with no
  problem to solve.
- **NixOS/nix-installer:** the official installer, now "Beta" [nixos-installer]. Nix is
  already installed; this is only relevant for a fresh Mac.
- **agenix / ragenix / agenix-rekey:** fine tools; sops-nix chosen (§4.2).
- **deploy-rs / colmena / comin:** three tools for pushing configs to remote hosts. deploy-rs
  v1.0.0 (2026-10-19) has "magic rollback" [deploy-rs] [gh-meta]. colmena now lives in
  nix-community [gh-meta]. comin is a pull-mode GitOps tool [comin]. One remote Host is
  covered by `nh os switch --target-host` [nh-changelog]. Revisit at two or more NixOS
  Hosts, or a headless typhon you change remotely.
- **nil:** last push 2026-07-26, versus nixd's 2026-10-24 [gh-meta]. nixd evaluates options,
  which nil does not advertise [nixd-readme] [nil].
- **alejandra:** you already use nixfmt, the official formatter [bon].
- **nvd, nix-output-monitor, dix standalone:** already bundled in nh (§3.1). nix-tree is
  already in the `nix` devShell.
- **nix-fast-build / nix-eval-jobs:** speed up big CI matrices [bon]. Two Hosts do not
  need them.
- **magic-nix-cache, cachix push, attic:** see §4.3.
- **Renovate's nix manager:** still in "beta testing, so you must opt-in" [renovate-nix].
  update-flake-lock is simpler.
- **impermanence:** NixOS-only and needs a root filesystem that is wiped on boot
  [impermanence]. Decide on it at the disko step (§4.1), not later.
- **lanzaboote** (Secure Boot, NixOS-only [lanzaboote]): revisit only if typhon dual-boots
  Windows with something that needs Secure Boot.
- **hjem:** now has a darwin module [hjem], but it manages files only. Your Features use HM's
  `programs.*` modules.
- **mac-app-util:** superseded by `copyApps` (§3.4).
- **nixvim / nvf:** you use VS Code.
- **devshell, devbox, flox:** overlap with `mkShell` + nix-direnv (and devenv if needed).
- **nixos-unified, Snowfall Lib, flake-utils-plus:** these impose their own structure, which
  conflicts with plain flake-parts + import-tree (see `dendritic-architecture.md`).
- **nixos-generators:** archived. Image building moved into nixpkgs as
  `nixos-rebuild build-image` [nixos-generators].
- **NUR, chaotic-nyx, nixpkgs-wayland:** no need identified.

---

## 7. Gotchas found in the current config

- **`ety` is not a trusted user on helios.** `nix-daemon.nix` sets
  `trusted-users = [ "root" "@wheel" ]` for both Classes. On macOS `wheel` contains only
  `root`, while `ety` is in `admin` [local]. The live `nix.conf` reads
  `trusted-users = root root @wheel` [local]. As a result, a flake's `nixConfig`
  substituters are not honoured for `ety`. **Fix:** use `@admin` in the darwin half and
  `@wheel` in the nixos half.
- **helios is not on this config yet.** `darwin-version --configuration-revision` reports
  `8088b5eaf750…-dirty`, the Refactor II state [local]. No `~/Applications/Home Manager Apps`
  exists yet [local].
- **The Homebrew brews all exist in nixpkgs.** `gh`, `ripgrep`, `rsync`, `p7zip`,
  `poppler-utils`, `rclone`, `ccache`, `fpart`, `pixi`, `colima`, `docker-client` and
  `docker-compose` all evaluate for `aarch64-darwin` [local]. `python@3.14` belongs in
  devShells.

---

## 8. How to proceed

Each step is small and can be committed on its own. Run `darwin-rebuild build` (or
`nh darwin build`) and diff before every switch.

1. **Switch helios to the dendritic config.** Run `darwin-rebuild build --flake .#helios`, then
   `nix store diff-closures /run/current-system ./result`, then switch. Everything below
   assumes this is done.
2. **Fix `trusted-users`** in `modules/features/nix-daemon.nix`: `@admin` for darwin,
   `@wheel` for nixos.
3. **nh**: add `programs.nh` to `nix-tools.nix`, and change or drop the `update` aliases.
   Update the CLAUDE.md command list to `nh darwin build` / `nh darwin switch`.
4. **Linters**: enable `programs.statix` (with `repeated_keys` disabled) and
   `programs.deadnix` in `modules/flake/formatter.nix`. Apply the fixes in a separate
   commit.
5. **Spotlight apps**: set `copyApps` on and `linkApps` off for darwin HM. Grant App
   Management permission when macOS asks.
6. **`unstable` for AI CLIs**: `unstable.claude-code` and `unstable.opencode` in
   `modules/users/ety.nix`.
7. **nix-index-database + comma**: add a flake input (with `follows`) and
   `modules/features/nix-index.nix`.
8. **Shrink Homebrew**: move CLI brews to `home.packages` a few at a time and keep brew for
   casks. Leave `cleanup = "none"` until the list is final. **ADR:** "brew is for casks only"
   and the later switch to `cleanup = "uninstall"` or `"zap"`, because zap deletes app data.
9. **CI**: add `.github/workflows/check.yml` (macOS + Ubuntu running `nix flake check` with
   `cachix/install-nix-action`).
10. **Weekly updates**: add `update-flake-lock` with a fine-grained PAT so its PRs trigger
    step 9 [uflock].
11. **Nice-to-haves, any order:** Touch ID sudo, nixd option completion for VS Code,
    mcp-nixos through `programs.claude-code`.
12. **When typhon arrives:**
    1. **ADR first:** disk layout (LUKS or not, ext4 or btrfs subvolumes, impermanence now or
       never) and whether typhon is a desktop or headless (this decides srvos vs stylix and a
       `desktop`/`server` Role).
    2. Add the `disko` input and `modules/hosts/typhon/_disko.nix`, then check it with
       `nix build .#nixosConfigurations.typhon.config.system.build.toplevel` in CI.
    3. Run nixos-anywhere from helios with
       `--generate-hardware-config nixos-facter ./modules/hosts/typhon/facter.json`. Then
       replace `_hardware.nix` with `hardware.facter.reportPath`, and `git add facter.json`.
    4. Add nixos-hardware only if typhon is a listed model.
13. **First secret:** write an ADR (sops-nix vs agenix), then add `modules/features/sops.nix`,
    `.sops.yaml`, and an age key derived from your SSH key.
14. **Later, when triggered:** a deploy tool (two or more remote Hosts), devenv
    (per-project services), nix-homebrew (fresh Mac), llm-agents.nix (unstable lag).

**ADR candidates:** step 8 (Homebrew scope and cleanup mode), step 12.1 (typhon disk layout
and Role), step 13 (secret tool). Also any future switch of Nix implementation
(Determinate/Lix).

---

## 9. Limitations

- READMEs were read at default-branch HEAD on 2026-10-26; the SHAs in §10 are those HEADs.
  Release notes were not read in full except nh's CHANGELOG.
- Nothing was built. Package existence was checked by evaluating the flake registry's
  nixpkgs (rev `9bc9b4b4e7b1`, helios's current pin) for `aarch64-darwin` [local]. 26.05
  versions were read from nixpkgs source.
- statix `repeated_keys` on the dendritic Feature files is predicted from the lint's
  definition, not run.
- `x86_64-linux` builds via the linux-builder were not tested.

---

## 10. Sources

List and metadata

- [bon] https://github.com/tolkonepiu/best-of-nix/blob/28f7f13e396b/README.md
- [gh-meta] `gh api repos/<owner>/<repo>` and `…/releases`, `…/tags` on 2026-10-26 (stars,
  `pushed_at`, `archived`, latest release). Redirects seen: `zhaofengli/colmena` to
  `nix-community/colmena`, `faukah/dix` to `manic-systems/dix`, `danth/stylix` to
  `nix-community/stylix`, `NixOS/experimental-nix-installer` to `NixOS/nix-installer`.
- [local] Commands on helios, 2026-10-26: `nix --version`, `/etc/nix/nix.conf`,
  `dscl . -read /Groups/{wheel,admin}`, `darwin-version --configuration-revision`,
  `nix flake check --help`, `nix eval` of package versions.

CLI helpers

- [nh-readme] https://github.com/nix-community/nh/blob/7be3a6c37f77/README.md
- [nh-changelog] https://github.com/nix-community/nh/blob/7be3a6c37f77/CHANGELOG.md
  ("Unreleased": rom replaces nom; `--target-host`)
- [nh-releases] https://github.com/nix-community/nh/releases
- [nixpkgs-nh] https://github.com/NixOS/nixpkgs/blob/d592aacecd35/pkgs/by-name/nh/nh/package.nix ·
  …/pkgs/by-name/nh/nh-unwrapped/package.nix (version 4.4.2)
- [hm-nh] https://github.com/nix-community/home-manager/blob/24f219058751/modules/programs/nh.nix
  (L56 `darwinFlake`, L100 gc assertion, L152 launchd)
- [dix] https://github.com/manic-systems/dix/blob/202e3cd29122/README.md · nvd: https://sr.ht/~khumba/nvd/
- [nid-readme] https://github.com/nix-community/nix-index-database/blob/93696586f346/README.md
- [nid-flake] …/blob/93696586f346/flake.nix (L44-57) · [nid-shared] …/blob/93696586f346/nix/shared.nix

Lint, format, LSP

- [statix-orig] https://github.com/oppiliappan/statix/blob/a5292554eddc/README.md
- [statix-repeated] https://github.com/molybdenumsoftware/statix/blob/b5b9cb750ba8/lib/src/lints/repeated_keys.rs
- [nixpkgs-statix] https://github.com/NixOS/nixpkgs/blob/d592aacecd35/pkgs/by-name/st/statix/package.nix
- [deadnix] https://github.com/astro/deadnix/blob/4a27fdea5e0d/README.md
- [tfn-statix] https://github.com/numtide/treefmt-nix/blob/0d6d739a833b/programs/statix.nix ·
  [tfn-deadnix] …/programs/deadnix.nix · [tfn-programs] …/programs ·
  [tfn-flakecheck] …/flake-module.nix#L50
- [nixd-readme] https://github.com/nix-community/nixd/blob/87012f56073f/README.md ·
  [nixd-config] …/nixd/docs/configuration.md
- [nil] https://github.com/oxalica/nil/blob/205c8ba65a7f/README.md
- [git-hooks] https://github.com/cachix/git-hooks.nix/blob/1ba1dbfe2873/README.md

macOS

- [nd-apps] https://github.com/nix-darwin/nix-darwin/blob/d31953cf55f9/modules/system/applications.nix
- [nd-pam] https://github.com/nix-darwin/nix-darwin/blob/d31953cf55f9/modules/security/pam.nix
- [nd-linux-builder] https://github.com/nix-darwin/nix-darwin/blob/d31953cf55f9/modules/nix/linux-builder.nix (L124)
- [hm-copyapps] https://github.com/nix-community/home-manager/blob/24f219058751/modules/targets/darwin/copyapps.nix ·
  [hm-linkapps] …/modules/targets/darwin/linkapps.nix
- [mac-app-util] https://github.com/hraban/mac-app-util/blob/039f33deef21/README.org
- [nix-homebrew] https://github.com/zhaofengli/nix-homebrew/blob/c11cccfdd36d/README.md

NixOS install and hardware

- [disko] https://github.com/nix-community/disko/blob/cedd626e11b6/README.md
- [nxa-readme] https://github.com/nix-community/nixos-anywhere/blob/92b94751fc01/README.md ·
  [nxa-quickstart] …/docs/quickstart.md (§8.1) · [nxa-ref] …/docs/reference.md (`--build-on`)
- [facter] https://github.com/nix-community/nixos-facter/blob/301b533c0542/README.md
- [facter-modules] https://github.com/nix-community/nixos-facter-modules (archived; README deprecation note)
- [nixpkgs-facter] https://github.com/NixOS/nixpkgs/tree/1f607aa79b63/nixos/modules/hardware/facter
- [nixos-generators] https://github.com/nix-community/nixos-generators (archived; README)
- [impermanence] https://github.com/nix-community/impermanence/blob/master/README.org ·
  [lanzaboote] https://github.com/nix-community/lanzaboote · nixos-hardware: https://github.com/NixOS/nixos-hardware
- [srvos] https://github.com/nix-community/srvos/blob/master/README.md · [srvos-darwin] https://github.com/nix-community/srvos/tree/master/darwin

Secrets

- [sops] https://github.com/Mic92/sops-nix/blob/442449fa7b1f/README.md (L9-46, L80-96, L180, L782-800)
- [sops-flake] …/blob/442449fa7b1f/flake.nix (L63-75) · [sops-hm] …/modules/home-manager/sops.nix (L380, L396)
- [agenix] https://github.com/ryantm/agenix/blob/5e5b88a0c8e5/README.md ·
  [agenix-flake] …/flake.nix (L33-40) · [agenix-hm] …/modules/age-home.nix (L264, L275)
- [ragenix] https://github.com/yaxitech/ragenix/blob/main/README.md

CI and caching

- [inix] https://github.com/cachix/install-nix-action/blob/master/README.md
- [nia] https://github.com/DeterminateSystems/nix-installer-action/blob/main/README.md (L36)
- [uflock] https://github.com/DeterminateSystems/update-flake-lock/blob/f02139a6c0ed/README.md (L180-210)
- [flake-checker] https://github.com/DeterminateSystems/flake-checker
- [mnc] https://github.com/DeterminateSystems/magic-nix-cache-action/blob/f69a2d3e148e/README.md
- [attic] https://github.com/zhaofengli/attic
- [renovate-nix] https://docs.renovatebot.com/modules/manager/nix/

Nix implementations

- [det] https://github.com/DeterminateSystems/determinate/blob/7dce88a77ee0/README.md (L67-111)
- [nixos-installer] https://github.com/NixOS/nix-installer/blob/bc6e313177c5/README.md
- [lix] https://github.com/lix-project/lix/blob/7229002d4991/README.md (mirror of git.lix.systems)

Deploy, dev envs, theming, AI

- [deploy-rs] https://github.com/serokell/deploy-rs/blob/1cec0527bd09/README.md ·
  [comin] https://github.com/nlewo/comin/blob/1399adecc682/README.md · colmena: https://github.com/nix-community/colmena
- [devenv] https://github.com/cachix/devenv/blob/80591248bdcd/README.md · dev-templates: https://github.com/the-nix-way/dev-templates
- [stylix] https://github.com/nix-community/stylix/blob/3e27b6c499e5/README.md · [catppuccin] https://github.com/catppuccin/nix
- [hjem] https://github.com/feel-co/hjem/blob/4cd448d5b322/flake.nix (L16-17)
- [llm-agents] https://github.com/numtide/llm-agents.nix/blob/0784674971b3/README.md (Installation, Binary Cache) ·
  [llm-agents-cc] …/packages/claude-code/hashes.json
- [nixpkgs-claude] https://github.com/NixOS/nixpkgs/blob/d592aacecd35/pkgs/by-name/cl/claude-code/manifest.json ·
  unstable: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/cl/claude-code/manifest.zst.json
- [mcp-nixos] https://github.com/utensils/mcp-nixos/blob/2e88096695be/README.md ·
  [nixpkgs-mcp] https://github.com/NixOS/nixpkgs/blob/d592aacecd35/pkgs/by-name/mc/mcp-nixos/package.nix
- [hm-claude] https://github.com/nix-community/home-manager/blob/24f219058751/modules/programs/claude-code.nix (L506 `mcpServers`)
