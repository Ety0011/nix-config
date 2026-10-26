# Composition by import into Roles, no feature registry

Features carry no `enable` flags: importing a module enables what it provides. Feature files merge their per-Class config into a few shared Role modules (`flake.modules.<class>.base`, later `dev`, `desktop`) instead of each exposing its own named module; a Host imports its Roles, and each Role's system module pulls in its `homeManager` counterpart via `home-manager.sharedModules`. Hosts declare themselves in a thin `configurations.<class>.<host>.module` option that maps to `*Configurations` and `checks`; it holds host modules only, never feature selection.

The previous design ("Refactor II", last state at `8088b5e`) used a central schema listing every Feature's enable flag, Features iterating over user profiles, an evaluator that auto-imported modules by name, and `specialArgs` to pass host data. Each new Feature required editing shared core code, and Features depended on Users instead of the reverse. The pattern author lists `enable` options, `specialArgs` pass-through and lower-level module name proliferation as anti-patterns (see `docs/research/dendritic-architecture.md`).

## Consequences

- Adding a Feature is adding a file; no import list changes.
- Imports are additive only. To leave a Feature off a Host, move it to a Role that Host doesn't take, rather than adding `mkForce false` overrides.
- `flake.modules` values have no `key` and are not deduplicated: import each module along exactly one path.
- `home-manager.sharedModules` applies to every User on a Host. Fine with one User; revisit when a second User shares a Host.
- The `configurations` option exists because `nix flake check` ignores `darwinConfigurations`; it must not grow feature or user fields.
