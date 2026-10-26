# nix-config

Declarative configuration for Etienne's machines and user environment, across macOS and NixOS.

## Language

**Feature**:
A single concern (git, zsh, sops) defined in one place, contributing to every Class it touches and to the Role it belongs to.
_Avoid_: aspect, module, profile

**Class**:
The kind of configuration a piece targets: `darwin`, `nixos`, or `homeManager`.
_Avoid_: platform, context

**Host**:
One concrete machine with its own configuration, e.g. `helios` (macOS) or `typhon` (NixOS).
_Avoid_: machine, system

**User**:
A person's account together with the Features they select, e.g. `ety`.
_Avoid_: profile

**Role**:
A named set of Features that a Host takes on as a whole, e.g. `base`, `dev`, `desktop`; Features place themselves into Roles, and a Role may contain another Role.
_Avoid_: bundle, profile, preset, tier
