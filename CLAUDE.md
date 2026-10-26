# nix-config

Dendritic flake for Etienne's Hosts (`helios`: aarch64-darwin, `typhon`: x86_64-linux stub) and User `ety`. Vocabulary (Feature, Class, Host, User, Role) is in `GLOSSARY.md`; the composition model and its reasons are in `docs/adr/0001-composition-by-import.md`. Read `docs/research/dendritic-architecture.md` before changing how Hosts, Roles or Home Manager are wired.

## Commands

```bash
nix flake check                           # evaluates and builds every Host
nix fmt                                   # treefmt
nh darwin build                           # build helios and diff against the running system
nh darwin switch                          # apply on helios (typhon: nh os switch)
```

## Rules

- A Feature file writes into Role modules (`flake.modules.<class>.base`); importing a module enables it. Give a Feature its own module name only when it is genuinely one-off.
- Hosts declare `configurations.<class>.<host>.module`; that option holds Host modules only.
- Reach other modules through `config.flake.modules` by closure; share values via declared top-level options.
- Import each module along exactly one path (`flake.modules` values are not deduplicated).
- New files are invisible to the flake until `git add`ed.
- `helios` is a live install: keep `system.stateVersion = 6` and its `home.stateVersion = "24.11"`.
- Homebrew cleanup is `"uninstall"`: a cask or brew dropped from `homebrew.*` is removed on the next switch. GUI apps go in casks, CLI tools in nixpkgs (`docs/adr/0003`).

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `Ety0011/nix-config`, via `gh`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md` plus `docs/adr/`. See `docs/agents/domain.md`.
