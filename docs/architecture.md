# Architecture

## Pattern

Dendritic Nix: every `.nix` file is a module in a single unified flake-parts evaluation context.
`import-tree` auto-discovers all files under `modules/` — no manual import lists.
Features are organized by concern (what they do), not by platform (where they run).

**New files must be `git add`ed before `nix flake check` sees them** — import-tree uses git ls-files.

## Module namespaces

```
flake.modules.darwin.*      nix-darwin system modules
flake.modules.nixos.*       NixOS system modules
flake.modules.homeManager.* home-manager user modules
```

All three contexts for a feature live in the same file (`features/git.nix` declares
`darwin.git`, `nixos.git`, and `homeManager.git`). Reading one file gives the complete
picture of what a feature does across all platforms.

## Directory layout

```
flake.nix                     Thin entry point — inputs + import-tree ./modules
modules/
  flake/                      Flake-parts setup (perSystem, pkgs, formatter, devShells)
    modules.nix               Registers flake.modules option namespace + treefmt
    nixpkgs.nix               pkgs with allowUnfree + unstable overlay
    formatter.nix             treefmt (nixfmt, prettier, shfmt)
    shells.nix                devShells (default, nix, c, python)
    systems.nix               Supported systems
  system/                     Universal host policy
    base.nix                  Nix daemon settings, GC, HM wiring, pkgs threading
                              darwin.base also enables homebrew and imports HM module
                              nixos.base imports HM module
    darwin-settings.nix       macOS system defaults (Dock, Finder, keyboard)
  hosts/                      Host declarations
    builder.nix               darwinHosts option + mapAttrs → darwinConfigurations
    Etiennes-MacBook-Pro/     darwin host
    nixos-machine/            NixOS host (not yet installed)
  features/                   Opt-in feature atoms
    git.nix  zsh.nix  ssh.nix direnv.nix  starship.nix
    nix-tools.nix  sops.nix  syncthing.nix
  users/
    ety/
      ety.nix                 All three contexts for ety
                              darwin: OS account, primaryUser, homebrew packages,
                                      explicit feature imports, HM wiring
                              nixos:  OS account, explicit feature imports, HM wiring
                              homeManager: packages, git identity, HM feature imports
```

## Data flow

```
flake.nix
  └─ import-tree ./modules          discovers all .nix files
       └─ flake-parts mkFlake       single unified evaluation context
            ├─ darwinHosts builder  mapAttrs → darwinConfigurations
            │    ├─ darwin.base     universal policy (nix settings, gc, homebrew enable)
            │    └─ darwin.ety      user account + features + HM wiring
            │         └─ homeManager.ety  packages + feature imports
            └─ nixosConfigurations
                 ├─ nixos.base      universal policy
                 └─ nixos.ety       user account + features + HM wiring
                      └─ homeManager.ety  (same module, platform-agnostic)
```

## Key mechanisms

### withSystem for pkgs
`nixpkgs.pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs)`
threads the perSystem pkgs (with unstable overlay) into each host — avoids importing
nixpkgs-unstable twice.

### darwinHosts builder
`builder.nix` declares `darwinHosts` as a typed `attrsOf submodule` option.
Each host declares `system`, `stateVersion`, `users`. Builder generates
`flake.darwinConfigurations` via `lib.mapAttrs`. NixOS hosts still use `nixosSystem`
directly — a `nixosHosts` builder can be added when a second NixOS host exists.

### Features are opt-in
Nothing is imported unless explicitly listed. `darwin.base` has zero feature imports.
Features are imported in the user module (`darwin.ety`, `nixos.ety`, `homeManager.ety`)
or in host-specific inline config blocks.

## Machines

| Host | System | Status |
|---|---|---|
| Etiennes-MacBook-Pro | aarch64-darwin | daily driver |
| nixos-machine | x86_64-linux | not yet installed |
