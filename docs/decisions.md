# Architectural Decisions

## Module organization

### No `common` namespace across darwin/nixos
Tried adding `flake.modules.common.*` as a shared context between darwin and nixos — rejected because flake-parts declares `flake.modules` with a fixed type that doesn't support new sub-namespaces. Tried `flake.common.*` as a separate option — rejected because it adds indirection for something solved more simply. **Resolution**: both `darwin.base` and `nixos.base` live in the same `base.nix` file, sharing a `let shared = { ... }` binding. The file is the sharing mechanism.

### No `mkUser` factory
Had a `mkUser` helper in `lib.nix` that stamped out the nixos/darwin/homeManager account boilerplate. Removed because it hides what a user actually is — reading `ety.nix` alone should tell you everything about ety. **Resolution**: each user file explicitly declares all three contexts. `lib.nix` was removed entirely.

### No inheritance chain (system-minimal → system-cli → system-desktop)
Started with a layered inheritance chain from the Dendritic guide. Removed because it conflated two orthogonal axes: system policy vs. user preferences. zsh and git ended up in a "system" layer when they're personal preferences. **Resolution**: two independent trees — host config and user config. They meet at one point: `home-manager.users.${username}` wired inside each user's darwin/nixos module.

### No `host` options
Tried declaring typed `host.name`, `host.username`, `host.stateVersion` options on the module system so any module could read `config.host.*`. The freeformType approach (`attrsOf anything`) worked but was reverted — felt like the wrong abstraction for now. **Resolution**: `let` bindings in `configuration.nix` for local reuse, values passed explicitly.

## System architecture

### `base.nix` is pure system policy
`base.nix` contains only things true for every host unconditionally: nix daemon settings, substituters, GC schedule, home-manager wiring options, registry pinning. Host identity (hostName, stateVersion) lives in `configuration.nix`. User preferences (zsh config, git, tools) live in user modules. These concerns must never mix.

### `withSystem` for pkgs
`nixpkgs.pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs)` threads the perSystem pkgs instance (with the unstable overlay) into every host. This avoids importing nixpkgs-unstable twice — once in perSystem and once inside each base module.

### `darwinHosts` builder
`modules/hosts/builder.nix` declares a `darwinHosts` option of type `attrsOf submodule`. Each darwin host is a simple declaration of system, stateVersion, and users. The builder generates `flake.darwinConfigurations` automatically via `lib.mapAttrs`. NixOS hosts still use `nixosSystem` directly in `configuration.nix` — a nixosHosts builder can be added when needed.

### zsh and direnv in `base.nix` system imports
`darwin.zsh`, `nixos.zsh`, `darwin.direnv`, `nixos.direnv` are imported in `base.nix` for all hosts. This is correct because registering zsh as a login shell and enabling direnv system-wide are host-level concerns, not user preferences. The user-level zsh/direnv config (programs.zsh, programs.direnv) is still opt-in via user modules.

## Features

### Features are opt-in at every level
Nothing is imported unless explicitly listed. `base.nix` imports only universal system-level features. Users import exactly the features they want. Aggregators (`cli.nix`, `dev.nix`) group related features for convenience but are themselves opt-in.

### Aggregators live in `modules/home/`
`cli.nix` groups: zsh, git, ssh, direnv, starship. `dev.nix` groups: nixTools. These are homeManager-only aggregators. Adding a new tool to the CLI stack means one line in `cli.nix` — every user importing `cli` gets it automatically.

### macOS-only packages via Homebrew casks
GUI apps not packaged for Darwin in nixpkgs go in `homebrew.casks` inside the user's `darwin.*` module. nixpkgs packages available on Darwin go in `home.packages`. Never add Linux-only packages to `home.packages` without a `lib.optionals` guard or better — put them in the `nixos.*` context directly.

### `system-settings` in `darwin.base`
macOS system defaults (Dock, Finder, keyboard) are imported in `darwin.base` as universal host policy. Every Darwin host gets them. Override specific values in the host's inline config block if needed.

## Naming conventions

- **Module keys**: camelCase (`systemSettings`, `nixTools`, `diskoWiring`, `homeManager`)
- **File names**: kebab-case (`system-settings.nix`, `nix-tools.nix`, `home-manager-base.nix`)
- **Host names**: natural casing matching the actual machine hostname (`Etiennes-MacBook-Pro`)
- **Usernames**: lowercase (`ety`)

## Rejected ideas

- `flake-parts partitions` for dev tooling isolation — too much complexity for current needs, can revisit later
- `osConfig` via `extraSpecialArgs` to homeManager — anti-pattern, homeManager modules should be self-contained
- `specialArgs` in general — sign of fighting the pattern, avoided throughout
- Per-user files in host `users/` directory — replaced by a single `users.nix` list, then merged into `configuration.nix` entirely
- Separate `home-manager-base.nix` — merged into `base.nix` for consistency with every other multi-context file
- `host-desktop` layer — premature abstraction with only one desktop host
- `window-manager.nix` for a single package — rectangle moved to user `home.packages`
