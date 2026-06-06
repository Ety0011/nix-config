# Patterns

Known good solutions, ready to reach for when the situation arises.
Not yet implemented — add when the trigger condition is met.

---

## Profiles + enable flags
**Trigger:** second distinct user or host type where a shared feature set needs
per-host/per-user deviations (one host wants everything a "developer" profile gives
except syncthing, another wants to add something on top).

**Problem with current explicit imports:** imports are additive. You can add features
to a host/user but cannot subtract a feature that a shared profile imports.

**Solution:**
1. Convert each feature to `mkEnableOption`:
```nix
# features/git.nix
flake.modules.darwin.git = { config, lib, self, ... }: {
  options.features.git.enable = lib.mkEnableOption "git";
  config = lib.mkIf config.features.git.enable {
    home-manager.sharedModules = [ self.modules.homeManager.git ];
  };
};
```
2. Create profiles that set flags to true:
```nix
# modules/profiles/developer.nix
flake.modules.darwin.profiles.developer = {
  features.git.enable = true;
  features.zsh.enable = true;
  features.direnv.enable = true;
  features.starship.enable = true;
  features.nixTools.enable = true;
};
```
3. Import all feature modules in `darwin.base` (dormant by default — no effect until enabled).
4. Host/user modules import a profile, then add or `mkForce false` overrides.

**Do not implement until** a second distinct host or user profile exists.

---

## `options.infra.*` for cross-module value sharing
**Trigger:** a value needs to be read by more than one feature module (e.g., syncthing
device IDs referenced in both syncthing config and a backup feature, or a domain name
used across multiple services).

**Problem with current approach:** values are either hardcoded per-feature or require
`specialArgs` injection, which is an anti-pattern.

**Solution:** declare top-level flake-parts options:
```nix
# modules/flake/infra.nix
{ lib, ... }:
{
  options.infra = {
    domain = lib.mkOption { type = lib.types.str; default = ""; };
    syncthingDeviceIds = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };
  };
}
```
Host modules set the values; feature modules read `config.infra.*` from the
top-level flake-parts context.

**Do not implement until** the first concrete cross-module value is identified.

---

## Hardware map with `_` prefix (NixOS)
**Trigger:** NixOS machine being configured — needs a hardware-specific config
(disko layout, hardware-configuration.nix) that must NOT be auto-discovered by
import-tree as a top-level flake-parts module.

**Solution:** prefix the file with `_` — import-tree skips files/dirs starting with `_`:
```
modules/hosts/nixos-machine/
  configuration.nix           # auto-discovered: declares nixosHosts entry
  _hardware.nix               # ignored by import-tree: manually imported by configuration.nix
```

Verify import-tree filter configuration supports `_` prefix before relying on this.

---

## nixos-shell for NixOS validation
**Trigger:** NixOS machine being provisioned — need to validate the config before
applying to physical hardware.

**Solution:** `nixos-shell` boots the NixOS config in a local QEMU VM:
```bash
nix run nixpkgs#nixos-shell -- --flake .#nixos-machine
```
Use `extendModules` to inject QEMU overrides (serial console, disable firewall,
mount project tree via 9p) without modifying the real config.

---

## nixosHosts builder
**Trigger:** second NixOS host exists (currently `nixosHosts` would add no value
over a direct `nixosSystem` call for a single host).

**Solution:** mirror `darwinHosts` builder in `builder.nix` — declare a `nixosHosts`
typed option, generate `nixosConfigurations` via `lib.mapAttrs`.
Model after `modules/hosts/builder.nix`.
