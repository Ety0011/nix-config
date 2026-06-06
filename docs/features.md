# Features

Tools and libraries used in this config — what they do and why.

---

## flake-parts
**Input:** `github:hercules-ci/flake-parts`

Structures the flake as a module system rather than a plain attribute set. Instead of
building `nixosConfigurations`, `darwinConfigurations`, `devShells`, etc. by hand in
`flake.nix`, each concern is declared in its own module and flake-parts composes them.

Provides:
- `perSystem` — per-architecture outputs (devShells, packages, checks)
- `flake.modules.*` — the custom option namespace for deferred host/user modules
- `withSystem` — threads a perSystem value (pkgs) into a host-level evaluation

Every `.nix` file in `modules/` is a flake-parts module. They all share one evaluation
context — any file can declare options, any file can read `config.*`.

**Why not plain flake:** impossible to split a plain flake across multiple files without
manual imports. flake-parts makes the whole tree one unified module system.

---

## import-tree
**Input:** `github:vic/import-tree`

Recursively discovers all `.nix` files under a directory and returns them as a flat
imports list for flake-parts. Used as:
```nix
flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)
```

Eliminates manual import maintenance — adding a file to `modules/` is enough to
register it with the unified evaluation context.

**Gotcha:** import-tree uses `git ls-files`. New files must be `git add`ed before
they are discovered. Untracked files are invisible to import-tree.

---

## nix-darwin
**Input:** `github:nix-darwin/nix-darwin`

Applies NixOS-style declarative configuration to macOS. Manages:
- System defaults (Dock, Finder, keyboard repeat)
- Homebrew packages (casks, brews) via the `nix-darwin-homebrew` module
- Login shell registration (`programs.zsh.enable`)
- System-wide direnv
- launchd daemons (used for nix GC profile pruning)
- Linking home-manager into the darwin activation

Each darwin host generates a `darwinConfiguration` entry consumed by
`darwin-rebuild switch --flake .`.

---

## home-manager
**Input:** `github:nix-community/home-manager`

Manages the user environment: dotfiles, shell config, git, SSH, packages installed
into `~/.nix-profile`. Used in module mode (not standalone) — wired into both
nix-darwin and NixOS via their respective home-manager modules:

```nix
imports = [ inputs.home-manager.darwinModules.home-manager ];  # darwin
imports = [ inputs.home-manager.nixosModules.home-manager ];   # nixos
```

`home-manager.useGlobalPkgs = true` shares the system pkgs instance so home-manager
does not evaluate nixpkgs a second time.

---

## sops-nix
**Input:** `github:Mic92/sops-nix`

Decrypts secrets at activation time using age/GPG keys and makes them available
as files or environment variables. Secrets are stored encrypted in the repo.

Provides modules for darwin, NixOS, and home-manager. Each context gets its sops
integration from `modules/features/sops.nix`.

---

## treefmt-nix
**Input:** `github:numtide/treefmt-nix`

Wraps `treefmt` (multi-formatter runner) as a flake-parts module. Configured in
`modules/flake/formatter.nix`:

| Formatter | Files |
|---|---|
| `nixfmt-rfc-style` | `*.nix` |
| `prettier` | `*.md`, `*.json`, `*.yaml` |
| `shfmt` | `*.sh` |

Exposes `checks.aarch64-darwin.treefmt` (CI-ready format check) and
`formatter.aarch64-darwin` (the `nix fmt` target).

---

## nixpkgs (stable + unstable overlay)

Three inputs:

| Input | Branch | Used for |
|---|---|---|
| `nixpkgs` | `nixos-25.11` | NixOS hosts |
| `nixpkgs-darwin` | `nixpkgs-25.11-darwin` | darwin hosts |
| `nixpkgs-unstable` | `nixos-unstable` | bleeding-edge packages via overlay |

The unstable overlay is applied in `modules/flake/nixpkgs.nix`:
```nix
overlays = [(final: _: { unstable = import inputs.nixpkgs-unstable { ... }; })];
```

Packages from unstable are accessed as `pkgs.unstable.somePackage`. The same pkgs
instance (with overlay) is threaded into every host via `withSystem` in `base.nix` —
nixpkgs-unstable is evaluated once, not once per host.

---

## deferredModule (flake-parts type)

Not a separate input — built into flake-parts.

`flake.modules.darwin.*`, `flake.modules.nixos.*`, and `flake.modules.homeManager.*`
are all typed as `deferredModule`. This means the module bodies are collected and
stored un-evaluated at the flake-parts level. They are only compiled into real
nix-darwin/NixOS/home-manager configs when a host evaluation triggers them.

This avoids infinite recursion from eager cross-evaluation and lets any number of
files safely contribute to the same target config space.
