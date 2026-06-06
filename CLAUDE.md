# nix-config

Dendritic Nix config for Etienne's machines. See `docs/architecture.md` for design overview,
`docs/decisions.md` for past decisions, `docs/patterns.md` for future patterns.

**New .nix files must be `git add`ed before import-tree discovers them.**

## Quick reference

```bash
update          # darwin-rebuild or nixos-rebuild (zsh alias)
nix fmt         # format all nix files
nix develop .#nix   # dev shell
```

## Common tasks

**Add a Homebrew cask** → `homebrew.casks` in `modules/users/ety/ety.nix`
**Add a nixpkgs package** → `home.packages` in `modules/users/ety/ety.nix`
**Add a CLI feature** → create `modules/features/my-feature.nix`, import in user module

**New feature file:**
```nix
{ ... }:
{
  flake.modules.darwin.myFeature = { ... }: { };
  flake.modules.nixos.myFeature = { ... }: { };
  flake.modules.homeManager.myFeature = { ... }: { };
}
```

**New darwin host** → `modules/hosts/<hostname>/configuration.nix`:
```nix
darwinHosts."My-Machine" = { system = "aarch64-darwin"; stateVersion = 6; users = [ "ety" ]; };
```

**New user** → `modules/users/<name>/<name>.nix` — model after `modules/users/ety/ety.nix`.

## Conventions
- Module keys: camelCase (`nixTools`, `darwinSettings`)
- File names: kebab-case (`nix-tools.nix`, `darwin-settings.nix`)
- Host/username: natural casing (`Etiennes-MacBook-Pro`, `ety`)
- All three contexts for a feature live in the same file
