# Features: re-evaluation and ranked candidates

Research date: 2026-10-26. Scope: the Feature layer (what `modules/features/` configures for daily
use), not ecosystem tools, which `best-of-nix.md` covers. Option paths were read from the locked
inputs: home-manager `release-26.05` @ `24f219058751`, nix-darwin `nix-darwin-26.05` @
`d31953cf55f9`, nixpkgs `nixos-26.05` @ `1f607aa79b63` and `nixpkgs-26.05-darwin` @
`d592aacecd35` (see §7). Usage evidence comes from helios, read-only [local]. "Fact" statements
carry a citation; **Assessment** marks my judgement.

---

## 1. TL;DR

- **Part A, current Features:** most are sound, but several lines are no-ops (they restate
  defaults) and five things are actually wrong or stale on helios:
  1. **Your git identity is shadowed.** A hand-made `~/.gitconfig` sets `user.name = Ety`, and git
     reads it after Home Manager's `~/.config/git/config` (`Etienne`), so commits say "Ety" [local].
  2. **gnupg (129 MiB) is in your closure for nothing.** With `home.stateVersion = "24.11"`, HM
     defaults `programs.git.signing.format` to `"openpgp"` and writes a gpg path into git's config
     [hm-git#L19-31] [local].
  3. **Rectangle comes from nixpkgs at 0.95, while the cask is 2.0.4** [local]. It also breaks
     ADR 0003 (GUI apps are casks), and its Accessibility grant is tied to its path.
  4. **typhon cannot be logged into after install.** `ety` has no password and no SSH key, root
     login is off and SSH passwords are off [local].
  5. **36 stale Home Manager generations (Feb 2026) pin old store paths.** The system `nix.gc`
     runs as root and never cleans them, and `~/.nix-profile` is a dangling link [local].
- **No-ops to delete:** `programs.home-manager.enable` (does nothing in module mode), starship
  `enableTransience` (fish only), every `enableZshIntegration`, most `history.*` lines, darwin
  `programs.zsh.enable`, darwin `users.users.ety.shell`, `nix.package`, `max-jobs`, the explicit
  `cache.nixos.org` substituter, `ServerAliveCountMax = 3`, and the redundant pipewire lines.
- **Strongly recommended additions** (few, high value):
  - Touch ID for `sudo`.
  - fzf for history search.
  - ripgrep (it was a brew, and the brew cleanup dropped it).
  - `programs.gh` instead of the bare package, which also gives typhon a git credential helper.
  - VS Code as a cask, which also restores the missing `code` command. Its settings stay
    unmanaged.
  - For typhon: `programs.nix-ld`, plus a login path (an authorized key and a password).
- **When needed:** Tailscale (already installed on helios), Syncthing, snapper, restic, Steam and
  GPU drivers, ollama, uv, git-lfs, `programs.claude-code`, docker on typhon, flake templates.
- **Skip:** atuin, carapace, tmux/zellij, eza, neovim/helix configs, `programs.vscode`, flatpak,
  `system.autoUpgrade`, 1Password/gpg integrations.

---

## 2. Evidence from helios

All from read-only commands on 2026-10-26 [local]. `~/.zsh_history` has 6018 lines and no
timestamps, so these counts cover the whole history, not a recent period.

- **Top commands:** `python` 846, `ros2`/`colcon` 662, `clear` 359, `source` 321 (219 venv
  `activate`, 95 ROS `setup.zsh`), `pixi` 294 (`shell` 123, `run` 102), `cd` 289, `git` 285
  (`switch` 87, `merge` 45, `checkout` 42, `push` 8, `pull` 1), `pip` 245, `direnv` 128 (`reload`
  74, `allow` 38), `sudo` 83 (`darwin-rebuild` 32), `grep` 60 (always in a pipe), `conda` 57,
  `ollama` 43, `runghc` 32, `rsync` 28, `colima` 28, `code` 21, `opencode` 13, `ssh` 12, `magick`
  11, `claude` 9, `./7zz` 8, `history` 9.
- **Zero uses:** fzf, rg, fd, bat, eza, zoxide, tmux (2), lazygit, btop, tldr, nvim, atuin, gpg.
- **No longer on PATH:** `code`, `ollama`, `magick`, `conda`, `rg`, `fd`, `7zz`. `python` is not
  on PATH either; `python3` is Apple's 3.9.6.
- **Projects:** 7 `flake.nix` and 4 `.envrc` (all `use flake`) under `~/Documents`. None of the
  `.envrc` files is tracked by git, and at least one exports an API token. venvs point at Nix
  store pythons. There is 1 `pixi.toml` and no `filter=lfs`.
- **Apps outside Homebrew:** VS Code, Firefox, Discord, WhatsApp, LocalSend, NordVPN, OpenMTP,
  Tailscale, eM Client, Dolphin, Ryujinx, Minecraft, Vorssaint, YouTube Music, plus the App Store
  apps Keynote, Pages and Numbers. The Dock pins Firefox, VS Code, WhatsApp and eM Client.
- **Hygiene:**
  - The SSH key has no passphrase (FileVault is on).
  - The git remote uses HTTPS, with osxkeychain as the credential helper.
  - The macOS firewall is off.
  - zsh starts in about 70 ms, and compinit runs twice (`/etc/zshrc` and `~/.zshrc`).
  - **One plaintext password is in `~/.zsh_history`** (an `RSYNC_PASSWORD=` line). It is not
    reproduced here.
- **Unmanaged leftovers:** `~/.gitconfig`, `~/.zprofile` (`brew shellenv`), `~/.nix-profile` →
  missing target, `~/.nix-defexpr/channels` → missing target,
  `~/.local/state/nix/profiles/home-manager-{1..36}-link`, and `*.home-manager.backup` files.

---

## 3. Part A: current Features, from scratch

Format: verdict, Class (darwin, nixos or HM), then the reason. "No-op" means the line restates
the option's default at the pinned revision. On darwin, deleting a `system.defaults` line does
not revert the setting: nix-darwin writes only non-null values [nd-defaults-write#L11]. To undo
one, set it to the opposite value once.

### 3.1 `darwin-settings.nix` (darwin, `base`)

- **Keep:** dock `autohide`, `show-recents`, `mru-spaces`, `minimize-to-application`; Finder
  `FXPreferredViewStyle`, `ShowPathbar`, `ShowStatusBar`, `FXEnableExtensionChangeWarning`; the
  `NSAutomatic…` substitutions; `ApplePressAndHoldEnabled = false` (your layout is US
  International-PC, which has dead keys for accents [local]).
- **Keep `InitialKeyRepeat = 15` / `KeyRepeat = 2`.** **Assessment:** these are the fastest
  values the System Settings sliders offer, and they are already live [local]. Lower values are
  possible but can cause double letters.
- **Remove (no-op):** `dock.orientation = "bottom"`; nix-darwin documents "bottom" as the default
  [nd-dock#L122].
- **Change:** set `AppleShowAllExtensions` once. Both `finder.` and `NSGlobalDomain.` variants
  exist [nd-finder#L63] [nd-nsglobal#L96]. **Assessment:** keep the `NSGlobalDomain` one.
- **User decision: `finder.AppleShowAllFiles = true`.** It shows `.DS_Store`, `.localized` and
  `~/Library` clutter in every Finder window. Cmd+Shift+. toggles hidden files on demand.
  **Assessment:** set it to `false` unless you browse dotfiles in Finder often; VS Code and the
  terminal already show them.

### 3.2 `direnv.nix` (HM, `base`)

- **Keep** `programs.direnv.enable` and `nix-direnv.enable`. nix-direnv roots each devShell in
  your gcroots, so `nix.gc` does not delete it [nix-direnv].
- **Remove (no-op):** `enableZshIntegration`. It defaults to `home.shell.enableZshIntegration`,
  which is `true` [hm-shell#L15-16] [local].
- **Optional:** `silent = true` hides the long `export +FOO -BAR` diff on every `cd`
  [hm-direnv#L100].

### 3.3 `git.nix` (HM, `base`) and the git identity in `users/ety.nix`

- **Keep:** `delta` (its `enableGitIntegration` defaults to `false`, so the line is needed
  [hm-delta#L57]), `init.defaultBranch` and `push.autoSetupRemote`.
- **Keep `pull.rebase = false`.** It is git's default behaviour (merge), stated explicitly so git
  stops printing the "how to reconcile" hint. You pull once in the whole history and merge 45
  times, so a merge workflow fits.
- **Global ignores: removed (2026-10-30).** This once said to keep `.envrc` globally ignored
  because `.envrc` files held tokens. It hid `.envrc` from `nix flake init` templates and from
  collaborators' view of a repo, so each repo's `.gitignore` now owns the list. The pattern is a
  committed `.envrc` (`use flake` + `dotenv_if_exists`) plus an ignored `.env` (dev-env.md §15).
- **Change:** add `programs.git.signing.format = null;`. The legacy default writes
  `gpg.format = openpgp` and a gnupg path [hm-git#L450-482], which keeps gnupg-2.4.9 (129.4 MiB)
  in the closure [local]. Use `null` until you adopt SSH signing (§4.3).
- **Fix outside the repo:** delete `~/.gitconfig` after choosing the name. git reads it after the
  XDG file, so `Ety` wins today [local]. If "Ety" is what you want, change the value in `ety.nix`
  instead.
- **Not needed:** `programs.git.lfs` (no LFS repos [local]); see §4.3.

### 3.4 `home-manager.nix` (darwin + nixos + HM, `base`)

- **Keep:** `useGlobalPkgs`, `useUserPackages`, `sharedModules`, `backupFileExtension`.
- **Remove (no-op):** the `flake.modules.homeManager.base.programs.home-manager.enable` block. Its
  config is `mkIf (cfg.enable && !config.submoduleSupport.enable)`, which is false when HM runs as
  a nix-darwin/NixOS module [hm-hm#L41].
- **Gotcha:** an existing `*.home-manager.backup` blocks the next backup of the same file. HM has
  `overwriteBackup` for that [hm-common#L100-122]. **Assessment:** don't enable it; delete the two
  stale backups (`~/.zshrc…`, `~/.ssh/config…`) once you have checked them.

### 3.5 `homebrew.nix` (darwin, `base`)

- **Keep** `cleanup = "uninstall"` (ADR 0003) and `environment.systemPath`. `systemPath` is what
  non-interactive shells and VS Code tasks see.
- **Change:** replace the hand-written `~/.zprofile` (`eval "$(brew shellenv)"`) with
  `homebrew.enableZshIntegration = true;`. This is the same `brew shellenv zsh`, but declared, and
  it also puts Homebrew's zsh completions (docker, colima) on `fpath` [nd-brew#L706-711]
  [nd-brew#L981]. Then delete `~/.zprofile`.
- **Know:** `onActivation.autoUpdate` and `upgrade` default to `false` [nd-brew#L113-140], so the
  colima/docker brews never upgrade on switch. Run `brew upgrade` now and then. Casks mostly
  update themselves.

### 3.6 `mac-apps.nix` (darwin → HM, `base`)

- **Keep.** `copyApps` works: `~/Applications/Home Manager Apps/Rectangle.app` exists [local].
  Once Rectangle moves to a cask (§3.14), no HM app is left, but the file costs nothing and
  covers the next one.

### 3.7 `nix-daemon.nix` (darwin + nixos, `base`)

- **Keep:** `experimental-features`, `trusted-users` (`@admin` / `@wheel`), `connect-timeout`,
  weekly `nix.gc` with `--delete-older-than 7d`, `nix.optimise` (Nix's `auto-optimise-store` is
  off by default, and the scheduled job is the usual darwin choice).
- **Remove (no-op):**
  - `nix.package = pkgs.nix` (the default on both [nd-nix#L233-235]).
  - `max-jobs = "auto"` (the default on both [nd-nix#L558-560] [nixos-nix#L171]).
  - The `https://cache.nixos.org?priority=10` substituter and its key. Both modules already add
    `cache.nixos.org` with `mkAfter` [nd-nix#L947-949] [nixos-nix#L371-373], so it is listed twice
    today [local]. Its own priority (40) already beats nix-community (41), so the `?priority=10`
    suffix changes nothing [cache-info].
  - On NixOS, `persistent = true` (the default [nixos-gc#L47-48]).
  - On darwin, the custom `interval`s. The defaults are Sunday 03:15 and 04:15
    [nd-gc#L32-34] [nd-opt#L38-40], one hour off yours.
- **Remove:** the `launchd.daemons.nix-gc-system-profiles` daemon (`+3` generations).
  **Assessment:** it duplicates `nix.gc`'s age policy with a second, count-based policy. It runs
  after gc, so whatever it frees waits a week anyway. It hard-codes a store-path command and
  exists only on darwin. One policy (7 days) is simpler to reason about.
- **Remove:** `keep-outputs = true`. Nix's default is `false`; `true` also keeps the build-time
  outputs of every live derivation [nix-conf]. nix-direnv already roots dev shells, so this only
  shrinks what gc can free.
- **Change:** move `warn-dirty` and `use-xdg-base-directories` from `extraOptions` into typed
  `nix.settings`, so typos fail at evaluation.
- **Keep `use-xdg-base-directories = true`.** **Assessment:** on this install its only visible
  effect is that Nix no longer uses `~/.nix-profile` and `~/.nix-defexpr` [nix-conf]. Your
  packages live in `/etc/profiles/per-user/ety` (`useUserPackages`). Delete the two dangling
  links by hand.
- **Keep `download-buffer-size` (1 GiB).** Nix 2.34's built-in default is 1 MiB [local], and a
  small buffer is what triggers "download buffer is full" stalls on large fetches [nix-conf].
  **Assessment:** 256 MiB would do, but this is not worth a change.
- **Optional:** drop `nix-community.cachix.org`. **Assessment:** your inputs `follows` your own
  nixpkgs, so their outputs rarely match that cache. Every cache miss adds one extra lookup. Low
  stakes either way.
- **One-time housekeeping:** `rm ~/.local/state/nix/profiles/home-manager-*-link`. These 36 GC
  roots are left over from standalone HM [local]. HM now keeps
  `~/.local/state/home-manager/gcroots/current-home` instead.

### 3.8 `nix-index.nix`, `nix-tools.nix`, `nixpkgs.nix` (HM / darwin + nixos, `base`)

- **Keep all three** as they are (adopted from best-of-nix §3). The only overlap is with the
  `nix` devShell (§3.15).

### 3.9 `ssh.nix` (nixos + HM, `base`)

- **Keep:** the NixOS `services.openssh` hardening and the HM `enableDefaultConfig = false` +
  `settings."*".ServerAliveInterval = 60` [hm-ssh#L748-772].
- **Remove (no-op):** `ServerAliveCountMax = 3`; "The default value is 3" [ssh-config].
- **Missing, and blocking for typhon:** see §4.6 (authorized key and password).

### 3.10 `starship.nix` (HM, `base`)

- **Keep:** `enable` and your `➜` characters.
- **Remove (no-op):**
  - `enableZshIntegration` (§3.2).
  - `enableTransience`: "only a valid option for the Fish shell" [hm-starship#L97-108].
  - `add_newline = true` (starship's own default [local: `starship print-config`]).

### 3.11 `zsh.nix` (darwin + nixos + HM, `base`)

- **Keep:** NixOS `programs.zsh.enable` (needed for a zsh login shell), HM `enable`,
  `autosuggestion`, `syntaxHighlighting`.
- **Remove (no-op):** darwin `programs.zsh.enable` (default `true` [nd-zsh#L19-21]). In HM,
  `enableCompletion`, `history.ignoreDups`, `ignoreSpace`, `share` and `size = 10000` are all
  defaults [hm-zsh-hist#L36-130] [hm-zsh#L170].
- **Change:** set `history.size = 100000` and `history.extended = true`. You are at 6018 of 10000
  lines, and history has no timestamps today [local] [hm-zsh-hist#L121]. **Assessment:** both are
  cheap and make fzf search (§4.1) and audits better.
- **Optional:** darwin `programs.zsh.enableGlobalCompInit = false`. It removes the first of the
  two compinit runs [nd-zsh#L86-89] [nd-zsh#L219]. Startup is already about 70 ms [local], so this
  is tidiness only.
- **Do by hand:** remove the plaintext password line from `~/.zsh_history`. `ignoreSpace` (on)
  keeps any command typed with a leading space out of history.

### 3.12 `plasma.nix`, `audio.nix`, `network-manager.nix`, `bluetooth.nix`, `firefox.nix` (nixos, `desktop`)

- **plasma:** keep. Remove (no-op) `sddm.wayland.enable = true`, which plasma6 sets with
  `mkDefault` [plasma6#L310-314].
- **audio:** **change to only `security.rtkit.enable = true`.** Any display manager turns on
  `services.graphical-desktop`, which sets `pipewire.enable`, `pulse.enable` and `alsa.enable`
  with `mkDefault` [graphical-desktop#L14-17] [graphical-desktop#L50-54]. Only rtkit is not set
  for you; pipewire adds it as a supplementary group when it is on [pipewire#L479].
- **network-manager, bluetooth:** keep. Plasma 6 only adds the applets if these are on
  [plasma6#L208-214]; it does not enable them.
- **firefox:** keep. Plasma wires in its browser integration automatically [plasma6#L391].
- **Already on by default, don't add:** `services.fwupd`, `services.power-profiles-daemon`
  [plasma6#L272-278], `hardware.graphics.enable`, `fonts.enableDefaultPackages`
  [graphical-desktop#L42-44], and `networking.firewall.enable` [nixos-fw#L73-75].

### 3.13 `users/ety.nix` (darwin + nixos + HM, User `ety`)

- **darwin:**
  - Remove `name = "ety"` (it defaults to the attribute name).
  - Remove `shell = pkgs.zsh`. nix-darwin only applies `shell` to users in `users.knownUsers`
    [nd-user#L73-84] [nd-users#L278-316], and the admin user must not be in that list. Your login
    shell stays Apple's `/bin/zsh` [local], which is fine.
  - Keep `home` (HM needs it).
- **Casks:** keep the list; see §3.14 and §4.5 for additions.
- **home.packages:**
  - Keep `pixi`, `rclone`, `rsync`, the `unstable` AI CLIs and `lldb`.
  - Keep `nodejs`: your Claude Code plugin hooks are `.js` files [local].
  - Replace `gh` with `programs.gh` (§4.3).
  - `htop` (1 use) is harmless.
- **nixos:** add the login path (§4.6).

### 3.14 Rectangle (in `users/ety.nix`)

- **Change:** move it from `home.packages` to `homebrew.casks = [ "rectangle" ]`. nixpkgs has 0.95
  and the cask 2.0.4 (auto-updating) [local]. A window manager needs the Accessibility grant,
  which is ADR 0003's exact reason for casks.

### 3.15 `modules/flake/dev-shells.nix`

- **Remove `default` and `nix`.** `default` is `git` + `vim`, both already installed; `nix`
  duplicates `nix-tools.nix` apart from `nix-tree`.
- **`c` and `python`: remove, or turn them into flake `templates` (§4.4).** Your projects use their
  own `flake.nix` + `use flake` [local]; `nix develop` appears 6 times in the whole history, never
  with `#c` or `#python`. **Assessment:** shells that live in nix-config but are used from other
  directories tend to rot.

---

## 4. Part B: candidates, ranked

Each candidate gives its tier, the reason for this user, the Class, where it would go, the option
path at 26.05, and any gotcha. Tiers: **Strongly recommended**, **When needed** (with its
trigger), **Nice to have**, **Skip**.

### 4.1 Shell UX

- **fzf: Strongly recommended.** Ctrl-R fuzzy history, Ctrl-T files, Alt-C directories. Your
  history is long, repetitive commands (`.venv/bin/python …`, cmake flag lines,
  `history | grep`) [local]. HM, both Hosts → `zsh.nix` (or a new `fzf.nix`) in
  `homeManager.base`: `programs.fzf.enable = true;`. zsh integration is on by default
  [hm-fzf#L190]. Gotcha: none with autosuggestions.
- **zoxide: Nice to have.** `cd` 289 [local]; `z proj` jumps by frecency. HM `base`:
  `programs.zoxide.enable` [hm-zoxide#L35]. **Assessment:** add it after fzf if you notice
  yourself retyping long `cd` paths.
- **direnv `layout pixi`: Nice to have.** `pixi shell` 123 [local]. direnv 2.38 ships
  `layout_pixi`, but 26.05 has 2.37.1 [direnv-stdlib] [local]. In `direnv.nix`,
  `programs.direnv.package = pkgs.unstable.direnv;`, then `.envrc` = `layout pixi`.
- **bat: Nice to have.** Plain `cat` 21. HM `programs.bat` [hm-bat#L39].
- **eza: Skip.** `ls` 142, but it only changes the look, and its zsh integration replaces `ls`
  with aliases [hm-eza#L54] [hm-eza#L145].
- **atuin: Skip.** fzf covers search. Sync needs an account or server, which is a decision without
  a need [hm-atuin#L32-146].
- **carapace, extra zsh plugins, oh-my-zsh: Skip.** You already have autosuggestions, syntax
  highlighting and completion.
- **tmux / zellij: Skip.** 2 uses [local].
- **Aliases (`programs.zsh.shellAliases`): Skip for now.** **Assessment:** the old `update` alias
  was dropped on purpose (`19b1283`). Add aliases only for commands you type daily.

### 4.2 CLI essentials

- **ripgrep: Strongly recommended.** It was one of your brews (best-of-nix §7) and disappeared when
  the brew list was cut. You run `grep` 60 times, always in a pipe. HM `base`:
  `programs.ripgrep.enable = true;` [hm-rg#L18] (or `home.packages`).
- **fd: Nice to have.** `find` 16. `programs.fd` [hm-fd#L14].
- **jq: Skip.** macOS ships `/usr/bin/jq` [local]. Add it on typhon only if you miss it.
- **btop: Skip.** `htop` is installed and used once.
- **tealdeer (tldr): Nice to have.** `programs.tealdeer` with `enableAutoUpdates`
  (default `true`) [hm-tldr#L92].
- **7-Zip (`_7zz`): When needed.** Trigger: the next archive. You run a downloaded `./7zz`
  [local]; `pkgs._7zz` is 26.04 [local].
- **imagemagick, poppler-utils: When needed.** `magick` 11 [local], but it is gone now. Add them to
  `home.packages` when a task needs them.

### 4.3 Git and GitHub

- **`programs.gh`: Strongly recommended** (replaces `gh` in `home.packages`). HM `base`,
  `git.nix`. `gitCredentialHelper.enable` defaults to `true` [hm-gh#L121-124], so HTTPS pushes
  authenticate through `gh` on both Hosts. typhon has no osxkeychain. Gotcha: HM then owns
  `~/.config/gh/config.yml` (read-only; set `programs.gh.settings` instead, e.g.
  `aliases.co = "pr checkout"`, which you have today [local]). `hosts.yml` (your token) stays
  yours [hm-gh#L160-184].
- **gh-dash: Skip.** `gh` is used 5 times [local].
- **lazygit: Nice to have.** You switch, merge and reset a lot [local], and lazygit makes those
  visual. **Assessment:** VS Code's git UI already covers this; add lazygit only for typhon/SSH.
- **difftastic: Skip.** delta is already the pager.
- **SSH commit signing: Nice to have.** You get "Verified" on GitHub and gnupg stays out.
  `programs.git.signing = { format = "ssh"; key = "~/.ssh/id_ed25519.pub"; signByDefault = true; };`
  [hm-git#L60-100]. Gotcha: add the key on GitHub as a signing key. **Assessment:** do it together
  with putting a passphrase on the key (§4.7).
- **git-lfs: When needed.** Trigger: a repo with `filter=lfs` (none today [local]).
  `programs.git.lfs.enable` [hm-git#L240].

### 4.4 Editors and dev environments

- **VS Code as a cask: Strongly recommended.** The app is in your Dock but not managed, and `code`
  (21 uses) is missing from PATH [local]. The cask links `/opt/homebrew/bin/code` [local: cask
  JSON]. darwin, `users/ety.nix`: `homebrew.casks = [ "visual-studio-code" ]`.
  - Gotcha: brew refuses to install over an existing app. Run
    `brew install --cask --adopt visual-studio-code` once before the switch [local:
    `brew install --help`].
  - Gotcha: with `cleanup = "uninstall"`, dropping the cask later uninstalls VS Code.
  - Settings, extensions and keybindings stay unmanaged. Use VS Code Settings Sync, which
    respects `3d8f6db`.
- **`programs.vscode`: Skip.** **Assessment:** HM makes `settings.json` read-only, and extensions
  come from nixpkgs or nix-vscode-extensions (best-of-nix §5). That is the friction you already
  rejected.
- **neovim / helix configs: Skip.** `vim` is used 8 times and macOS ships it. On typhon NixOS
  ships `nano`. **Nice to have** instead: set `home.sessionVariables.EDITOR` (e.g.
  `"code --wait"` once `code` is back), so `git merge` messages open in VS Code.
- **Flake templates: When needed.** Trigger: the next new C or Python project. Add a `templates`
  output (flake-parts `flake.templates`) with `flake.nix` + `.envrc`, then
  `nix flake init -t ~/nix-config#python`. This replaces the `c`/`python` devShells (§3.15).
- **uv: When needed.** Trigger: a new pip/venv project without pixi. It manages its own Pythons,
  so no store-path venvs that break after gc. HM `programs.uv` [hm-uv#L25].
- **ollama: When needed.** 43 uses, now gone [local]. On darwin either the `ollama-app` cask (GUI,
  ADR 0003) or HM `services.ollama` (a launchd agent [hm-ollama#L24] [hm-ollama#L108]).
  **Assessment:** the cask. GPU access and self-update matter more here than pinning.
- **`programs.claude-code`: When needed.** Trigger: you want a versioned global `CLAUDE.md`,
  skills or MCP servers (e.g. mcp-nixos, best-of-nix §5). HM generates `settings.json` as a
  read-only store file [hm-claude#L121] [hm-claude#L691]. Your `settings.json` is written by
  plugins (hooks, `enabledPlugins`) [local], so manage `context`/`skills` only and leave
  `settings` unset.
- **`programs.opencode`: Skip for now.** `~/.config/opencode` holds a hand-run bun project
  (`node_modules`, `bun.lock`) [local].
- **Docker on macOS: keep the colima brews (ADR 0003).** **Nice to have, needs an ADR change:** HM
  26.05 has `services.colima` with launchd agents and declarative profiles [hm-colima#L17]
  [hm-colima#L264]. You run `colima start` 20 times [local], so it would start on login and drop
  the last brews.
- **Docker on typhon: When needed.** Trigger: container work on typhon.
  `virtualisation.docker.enable` (add `docker` to `extraGroups`), or podman with `dockerCompat`.
  nixos, a `dev` Role or `desktop`.

### 4.5 macOS (helios)

- **Touch ID for sudo: Strongly recommended.** `sudo` 83, `darwin-rebuild` 32, and `nh` asks for
  sudo on every switch [local]. darwin `base`, `darwin-settings.nix`:
  `security.pam.services.sudo_local.touchIdAuth = true;` [nd-pam#L28-36]. It writes
  `/etc/pam.d/sudo_local`, which survives macOS updates [nd-pam#L60-100]. Add `reattach = true`
  only if you start using tmux [nd-pam#L49-58].
- **More casks for apps you already run: Nice to have, user decision.** Firefox (`firefox`),
  Tailscale (`tailscale-app`), LocalSend, Discord, WhatsApp, OpenMTP, eM Client (`emclient`) and
  others all have casks [local]. Pages, Keynote and Numbers go in `homebrew.masApps`
  [nd-brew#L857]. Gotcha: `--adopt` each one first. **Assessment:** declare the apps you would
  reinstall on a new Mac; leave games and one-offs (eTax) manual.
- **Screenshots folder: Nice to have.** `system.defaults.screencapture.location = "~/Pictures/Screenshots";`
  [nd-screencapture#L8]. The folder must exist.
- **Application firewall: Nice to have.** It is off today [local].
  `networking.applicationFirewall = { enable = true; enableStealthMode = true; };`
  [nd-alf#L20-48]. Gotcha: macOS asks once per app that listens (LocalSend, `python -m http.server`).
- **Nerd Font: Nice to have.** Only needed if you switch starship to a Nerd Font preset, because
  your `➜` prompt needs none. darwin `fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];`
  [nd-fonts#L18], then pick the font in Terminal and VS Code.
- **Dock `persistent-apps`: Skip for now.** It overwrites the Dock on every switch
  [nd-dock#L130], and it only pays off once the apps it lists are declared too.
- **`system.keyboard` remaps: Skip.** You use CapsLockNoDelay, so you keep Caps Lock
  [nd-keyboard#L11-23].
- **`system.startup.chime`, `power.*`: Skip.** No need.

### 4.6 NixOS desktop (typhon)

- **Login path: Strongly recommended, before install.** Today `users.users.ety` has no password
  and no key [local]. With `PermitRootLogin = "no"` and `PasswordAuthentication = false`, the
  installed system has no way in, and `wheel` needs a password for sudo.
  - nixos, `users/ety.nix`: `openssh.authorizedKeys.keys = [ "<contents of ~/.ssh/id_ed25519.pub>" ];`.
    A public key is safe to commit.
  - Plus a password: `initialHashedPassword` (from `mkpasswd`) to change with `passwd` after the
    first login (`users.mutableUsers` defaults to `true`), or `hashedPasswordFile` via sops once
    that exists (best-of-nix §4.2).
  - **User decision:** a hash in a public repo can be attacked offline. Use a long passphrase or
    wait for sops.
- **`programs.nix-ld`: Strongly recommended.** pixi/conda packages, pip manylinux wheels and VS Code
  extension binaries are prebuilt for a standard Linux loader. nix-ld exists to "run unpatched
  dynamic binaries on NixOS" [nix-ld]. You use pixi, conda and pip heavily [local]. nixos `base`
  (or a future `dev` Role): `programs.nix-ld.enable = true;` [nixos-nix-ld#L25].
- **Tailscale: When needed.** Trigger: typhon is installed. You already run Tailscale.app on
  helios [local], so the account exists. nixos `base`: `services.tailscale.enable = true;`. Then
  SSH from helios works anywhere without opening ports. On helios, declare the `tailscale-app`
  cask instead of the nix-darwin `services.tailscale` daemon, so there is one client.
- **GPU drivers: When needed.** Trigger: you know typhon's GPU. `hardware.graphics` is already on;
  NVIDIA needs `services.xserver.videoDrivers = [ "nvidia" ]` + `hardware.nvidia.*`. A Host
  module, not a Feature.
- **Steam: When needed.** Trigger: gaming on typhon. You had a Steam cask and run Minecraft,
  Dolphin and Ryujinx [local]. `desktop` or a `gaming` Role: `programs.steam.enable = true;`
  (unfree, already allowed).
- **Printing: When needed.** Trigger: a printer. `services.printing.enable = true;` (Plasma adds
  its print manager automatically [plasma6#L218]).
- **snapper on `/home`: Nice to have, decide before install.** ADR 0002 picked btrfs for this.
  `services.snapper.configs.home = { SUBVOLUME = "/home"; TIMELINE_CREATE = true; TIMELINE_CLEANUP = true; };`.
  Gotcha: the subvolume "has to contain a subvolume named .snapshots" [nixos-snapper#L46-53]. Add
  `"/home/.snapshots" = { };` to `_disko.nix` now, so it is created at install.
- **restic backup of `/home`: When needed.** Trigger: typhon holds data that exists nowhere else.
  `services.restic.backups.<name>` with an off-machine repo; the password goes in sops. Snapshots
  are not backups.
- **LocalSend / KDE Connect: Nice to have.** You use LocalSend on helios and have an Android phone
  (OpenMTP, adb) [local]. `programs.localsend = { enable = true; openFirewall = true; };`
  [nixos-localsend#L9-26]; `programs.kdeconnect.enable` opens ports 1714–1764 [nixos-kdec#L31-37].
  **Assessment:** LocalSend alone, since it already works across your devices.
- **Slimmer Plasma: Nice to have.** `services.orca.enable = false;` and
  `services.speechd.enable = false;`. Both are only `mkDefault` [plasma6#L304]
  [graphical-desktop#L48]. Keep them if you want the screen reader.
- **Skip:**
  - flatpak (a second package manager; nixpkgs covers your apps).
  - `system.autoUpgrade` (ADR 0004: lock bumps are manual).
  - `boot.plymouth` (cosmetic).
  - fwupd, power-profiles-daemon and firewall (already on, §3.12).

### 4.7 Cross-host and security

- **Syncthing: When needed.** Trigger: a folder to keep live on both Hosts. Your Obsidian vault is
  the obvious one. HM `services.syncthing` runs as a launchd agent on darwin [hm-syncthing#L912].
  Gotcha: device certificates are secrets, so add sops first. The `tray` option is Linux-only
  [hm-syncthing#L947].
- **SSH key passphrase + Keychain: Nice to have.** The key has no passphrase [local]. Add one
  (`ssh-keygen -p`), then `programs.ssh.settings."*" = { AddKeysToAgent = "yes"; UseKeychain = "yes"; };`
  on darwin only. `UseKeychain` exists only in Apple's `/usr/bin/ssh`, which is the one you run
  [local].
- **`programs.ssh` matchBlocks for GitHub: Skip.** The remote and `gh` use HTTPS [local].
- **gpg / gpg-agent, 1Password, Bitwarden: Skip.** No apps, no keys, no history [local].
- **Theming (stylix): see best-of-nix §4.5.** The trigger is still "typhon has a desktop".

---

## 5. Part C: how to proceed

Each step can be committed on its own. Run `nh darwin build` before every `nh darwin switch`.

1. **Housekeeping, no repo change.** Choose the git name, then `rm ~/.gitconfig`. Remove
   `~/.local/state/nix/profiles/home-manager-*-link`, the dangling `~/.nix-profile` and
   `~/.nix-defexpr`, the two `*.home-manager.backup` files, and the password line in
   `~/.zsh_history`.
2. **`refactor: drop no-op options`.** Covers §3.1 (orientation), §3.2, §3.4, §3.7 (`nix.package`,
   `max-jobs`, the `cache.nixos.org` entry, `persistent`, the intervals), §3.9, §3.10, §3.11, §3.12
   (sddm wayland, pipewire lines) and §3.13 (`name`, `shell`). Expect `nh darwin build` to show an
   empty or near-empty diff. That proves they were no-ops.
3. **`fix: git signing format`.** `programs.git.signing.format = null;`. The diff should show
   gnupg leaving the closure.
4. **`refactor: nix-daemon gc policy`.** Remove the `+3` daemon and `keep-outputs`, and move
   `extraOptions` into `nix.settings`.
5. **`feat: brew shell integration`**, then delete `~/.zprofile`.
6. **`fix: Rectangle as a cask`** (`brew install --cask --adopt rectangle` first; grant
   Accessibility again).
7. **`feat: Touch ID for sudo`.**
8. **`feat: VS Code cask`** (`--adopt` first).
9. **`feat: fzf, ripgrep, programs.gh`**, plus `history.size`/`extended`.
10. **`refactor: drop devShells`** (or turn them into `templates` the first time you need one).
11. **Before installing typhon:** the login path (§4.6), `programs.nix-ld`, the
    `/home/.snapshots` subvolume in `_disko.nix`, and `services.tailscale`. Then the remaining
    When-needed items as their triggers fire.

**Needs your decision:**

- The git display name ("Etienne" or "Ety").
- `AppleShowAllFiles`.
- Which unmanaged apps become casks (ADR 0003 already covers the principle, so no new ADR).
- typhon's password approach (a hash in the repo now, or wait for sops).

**ADR candidates:**

- Moving colima to HM `services.colima`, which amends ADR 0003.
- Syncthing or restic, which need the sops ADR from best-of-nix §8 first.
- Managing Claude Code config through HM, if you go beyond `context`/`skills`.

---

## 6. Limitations

- Nothing was built or switched. No-op claims come from module source and from `nix eval` of
  the current config, not from a before/after closure diff. Step 2's build diff is the check.
- History counts cover the whole history, not recent use. Commands typed in VS Code's terminal
  are included; commands run by VS Code tasks are not.
- `defaults read` showed the live values but not which tool wrote them.
- Cask versions and tokens come from `brew info --json=v2` against Homebrew's API on
  2026-10-26 [local].
- typhon's hardware, GPU and network are unknown, so its items are triggers, not plans.

---

## 7. Sources

Local evidence

- [local] helios, 2026-10-26: `~/.zsh_history` (counted with `LC_ALL=C grep -a`),
  `ls /Applications ~/Applications`, `brew list`, `brew info --cask --json=v2`, `defaults read`,
  `git config --show-origin`, `ls -la ~ ~/.config ~/.ssh ~/.local/state/nix/profiles`,
  `ssh-keygen -y -P ""` (exit status only), `fdesetup status`, `socketfilterfw --getglobalstate`,
  `nix config show` (with and without config files), `nix path-info -rSh`,
  `nix-store --gc --print-roots`, `nix eval` of helios/typhon options, `starship print-config`,
  `/usr/bin/time zsh -i -c exit`.
- [cache-info] https://cache.nixos.org/nix-cache-info (Priority: 40) ·
  https://nix-community.cachix.org/nix-cache-info (Priority: 41), fetched 2026-10-26.
- [ssh-config] `ssh_config(5)` on macOS (OpenSSH 10.3p1), `ServerAliveCountMax`.

home-manager @ `24f2190587513b9c2f73db112a17844ae912d965` (release-26.05)

- [hm-git] https://github.com/nix-community/home-manager/blob/24f2190587513b9c2f73db112a17844ae912d965/modules/programs/git.nix
  (L19-31 stateVersion default, L60-100 signing, L240 lfs, L450-482 signer)
- [hm-delta] …/modules/programs/delta.nix (L57) · [hm-hm] …/modules/programs/home-manager.nix (L41)
- [hm-common] …/nixos/common.nix (L100-122 backup options)
- [hm-shell] …/modules/lib/shell.nix (L15-16) · [hm-direnv] …/modules/programs/direnv.nix (L100)
- [hm-starship] …/modules/programs/starship.nix (L97-108) · [hm-ssh] …/modules/programs/ssh.nix (L748-772)
- [hm-zsh] …/modules/programs/zsh/default.nix (L170-183) · [hm-zsh-hist] …/modules/programs/zsh/history.nix (L36-130)
- [hm-fzf] …/modules/programs/fzf.nix (L190) · [hm-zoxide] …/modules/programs/zoxide.nix (L35) ·
  [hm-atuin] …/modules/programs/atuin.nix (L32-146) · [hm-eza] …/modules/programs/eza.nix (L54, L145) ·
  [hm-bat] …/modules/programs/bat.nix (L39) · [hm-rg] …/modules/programs/ripgrep.nix (L18) ·
  [hm-fd] …/modules/programs/fd.nix (L14) · [hm-tldr] …/modules/programs/tealdeer.nix (L92) ·
  [hm-uv] …/modules/programs/uv.nix (L25)
- [hm-gh] …/modules/programs/gh.nix (L121-124, L160-184)
- [hm-claude] …/modules/programs/claude-code.nix (L121, L691) · opencode: …/modules/programs/opencode.nix (L107)
- [hm-colima] …/modules/services/colima.nix (L17, L264) · [hm-ollama] …/modules/services/ollama.nix (L24, L108)
- [hm-syncthing] …/modules/services/syncthing.nix (L912, L947)

nix-darwin @ `d31953cf55f9027a56e9be938daf5db8c5655663` (nix-darwin-26.05)

- [nd-defaults-write] https://github.com/nix-darwin/nix-darwin/blob/d31953cf55f9027a56e9be938daf5db8c5655663/modules/system/defaults-write.nix (L11)
- [nd-dock] …/modules/system/defaults/dock.nix (L122, L130) · [nd-finder] …/modules/system/defaults/finder.nix (L11, L63) ·
  [nd-nsglobal] …/modules/system/defaults/NSGlobalDomain.nix (L96, L291-316) ·
  [nd-screencapture] …/modules/system/defaults/screencapture.nix (L8)
- [nd-zsh] …/modules/programs/zsh/default.nix (L19-21, L86-89, L219)
- [nd-user] …/modules/users/user.nix (L73-84) · [nd-users] …/modules/users/default.nix (L278-316)
- [nd-pam] …/modules/security/pam.nix (L28-60, L60-100)
- [nd-brew] …/modules/homebrew.nix (L113-140, L706-711, L857, L981)
- [nd-nix] …/modules/nix/default.nix (L233-235, L558-560, L947-949)
- [nd-gc] …/modules/services/nix-gc/default.nix (L32-34) · [nd-opt] …/modules/services/nix-optimise/default.nix (L38-40)
- [nd-alf] …/modules/networking/applicationFirewall.nix (L20-48) · [nd-fonts] …/modules/fonts/default.nix (L18) ·
  [nd-keyboard] …/modules/system/keyboard.nix (L11-23) · startup chime: …/modules/system/startup.nix (L13) ·
  tailscale: …/modules/services/tailscale.nix (L16)

nixpkgs @ `1f607aa79b6356ed45d3cd3c8079c196e79efa2c` (nixos-26.05)

- [plasma6] https://github.com/NixOS/nixpkgs/blob/1f607aa79b6356ed45d3cd3c8079c196e79efa2c/nixos/modules/services/desktop-managers/plasma6.nix
  (L208-218, L272-278, L301-314, L391)
- [graphical-desktop] …/nixos/modules/services/misc/graphical-desktop.nix (L14-17, L42-54)
- [pipewire] …/nixos/modules/services/desktops/pipewire/pipewire.nix (L131-150, L479)
- [nixos-nix] …/nixos/modules/config/nix.nix (L171, L371-373) · [nixos-gc] …/nixos/modules/services/misc/nix-gc.nix (L47-48)
- [nixos-fw] …/nixos/modules/services/networking/firewall.nix (L73-75)
- [nixos-snapper] …/nixos/modules/services/misc/snapper.nix (L46-53)
- [nixos-nix-ld] …/nixos/modules/programs/nix-ld.nix (L25) · [nixos-localsend] …/nixos/modules/programs/localsend.nix (L9-26) ·
  [nixos-kdec] …/nixos/modules/programs/kdeconnect.nix (L31-37)
- Also present at this rev (paths checked): `services/networking/tailscale.nix`, `programs/steam.nix`,
  `services/printing/cupsd.nix`, `services/backup/restic.nix`, `services/desktops/flatpak.nix`,
  `system/boot/plymouth.nix`, `tasks/auto-upgrade.nix`, `services/networking/syncthing.nix`.

Upstream docs

- [nix-conf] https://nix.dev/manual/nix/2.34/command-ref/conf-file.html (`download-buffer-size`,
  `keep-outputs`, `use-xdg-base-directories`, `max-jobs`)
- [nix-direnv] https://github.com/nix-community/nix-direnv/blob/master/README.md ("prevents garbage
  collection of build dependencies by symlinking the resulting shell derivation in the user's
  `gcroots`")
- [direnv-stdlib] https://github.com/direnv/direnv/blob/28a73d1df3f387e16f3c7fa888c2a049e0059e7a/stdlib.sh
  (v2.38.2, `layout_pixi`; absent in v2.37.1) · pixi: https://pixi.prefix.dev/latest/integration/third_party/direnv/
- [nix-ld] https://github.com/nix-community/nix-ld/blob/main/README.md
