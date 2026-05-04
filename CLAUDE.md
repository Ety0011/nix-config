# nix-config

Nix configuration for Etienne's machines using flake-parts + import-tree (dendritic pattern).
import-tree auto-discovers every .nix file under modules/ — no manual imports needed.

## Machines
- **Etiennes-MacBook-Pro** — aarch64-darwin, daily driver
- **nixos-machine** — x86_64-linux, not yet installed

## Key conventions
- Module keys use camelCase (`systemSettings`, `nixTools`, `diskoWiring`)
- File names use kebab-case (`system-settings.nix`, `nix-tools.nix`)
- Host names and usernames use their natural casing
- All three contexts (nixos, darwin, homeManager) for a feature live in the same file
- Features are opt-in — nothing is imported unless explicitly listed

## Adding a package
- macOS GUI app available on nixpkgs → `home.packages` in `modules/users/ety/ety.nix`
- macOS GUI app only on Homebrew → `homebrew.casks` in `modules/users/ety/ety.nix`
- CLI tool for ety → `home.packages` or via a feature in `modules/features/`
- System-wide tool → `environment.systemPackages` in the relevant base or host module

## Adding a feature
1. Create `modules/features/my-feature.nix`
2. Declare `flake.modules.darwin.myFeature`, `flake.modules.nixos.myFeature`, and/or `flake.modules.homeManager.myFeature` as needed
3. Import it where appropriate — in `base.nix` if universal, in a user module if personal, in an aggregator if it fits cli/dev

## Adding a host (darwin)
Add an entry to `darwinHosts` in a new `modules/hosts/<machine-name>/configuration.nix`:
```nix
darwinHosts."My-Machine-Name" = {
  system = "aarch64-darwin";
  stateVersion = 6;
  users = [ "ety" ];
};
```

## Adding a user
Create `modules/users/<username>/<username>.nix` declaring all three contexts explicitly.
Model it after `modules/users/ety/ety.nix`.

## Rebuild
```
update          # alias in zsh — picks darwin-rebuild or nixos-rebuild automatically
nix fmt         # format all nix files
nix develop .#nix   # dev shell for working on the config
```

## Module system
- `flake.modules.darwin.*` — nix-darwin system modules
- `flake.modules.nixos.*` — NixOS system modules  
- `flake.modules.homeManager.*` — home-manager user modules
- `darwinHosts` — typed option in builder.nix that auto-generates darwinConfigurations
- `withSystem` in base.nix threads perSystem pkgs (with unstable overlay) into hosts
