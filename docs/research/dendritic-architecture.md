# Dendritic architecture for a single-user darwin + NixOS + home-manager config

Research date: 2026-10-26. Sources are pinned to commits where possible (see §8).
"Fact" statements carry a citation; **Assessment** marks my judgement.

---

## 1. TL;DR

- **Use plain flake-parts + import-tree.** Do not adopt den or flake-aspects. Den is v0.x with
  breaking changes in 7 of its 19 releases, and its README says it "no longer relates to the
  Dendritic name" [den-readme]. Its author moved his own config off den to a new framework
  ("ren", created 2026-10-19) on 2026-10-22 [vix-ren].
- **Keep "import = enable, no `enable` flags".** The pattern's author added exactly this rule to
  the README in 2026-07 [dendritic#enable-options].
- **Keep hosts building their own configurations, but import `inputs.nix-darwin.flakeModules.default`.**
  flake-parts declares no option for `flake.darwinConfigurations`. Without that module, a second
  darwin host defined in another file is a merge error [fp-flake.nix] [nd-flake-module].
- **Change: avoid one named module per Feature per Class.** The author lists "lower-level module
  name proliferation" as an anti-pattern [dendritic#proliferation]. In the draft, a cross-class
  feature costs up to three import lines (darwin.ety, nixos.ety, homeManager.ety). Merge
  always-on features into a few collector modules (`base`, and later `desktop`), and give a
  named module only to features that are genuinely optional.
- **Change: a Feature's system half should pull in its own HM half**, via
  `home-manager.sharedModules` (Doc-Steve's "Multi Context Aspect") [ds-aspects]. Then a User
  writes one import per feature, not two.
- **Caveat: `flake.modules` modules have no `key`, so they are not deduplicated.** If a Bundle
  and a User both import `darwin.git`, its definitions are applied twice [fp-modules.nix#L24]
  [fp#299] [nixpkgs-modules#L536]. Either import each module along exactly one path, or set
  `key` yourself, as mightyiam does [infra-base].
- **pkgs: one stable `nixpkgs` input plus an `unstable` overlay, set in the `base` module.**
  Use `home-manager.useGlobalPkgs = true` so home-manager sees the overlay [hm-common#L95].
  Use no `specialArgs` and no `extraSpecialArgs` [dendritic#specialargs-pass-thru].
- **Files Nix does not see:** flakes only see git-tracked files. This comes from flakes, not from
  import-tree [nix-flake-ref]. import-tree itself only ignores paths containing `/_` and files
  not ending in `.nix` [it-default#L64].
- **Optional, the author's own style:** a thin `configurations.<class>.<host>.module` option
  (a deferredModule) that maps into `*Configurations` and `checks`. This is not a registry of
  features and not an evaluator. The author recommends declaring options like this over using
  only `flake.modules` [dendritic#not-declaring-options] [infra-nixos].

---

## 2. What the dendritic pattern is (per its author)

All facts below are from [dendritic-readme] (mightyiam, commit `6c76240`, 2026-09-04).

- **Definition.** There is a _top-level configuration_, usually flake-parts, though "it does not
  have to be". In it, "every Nix file except for entry points such as `default.nix` and `flake.nix`
  is a module of the top-level configuration". Each top-level module:
  - "implements a single feature",
  - "...across all configurations that that feature applies to",
  - "is at a path that serves to name that feature".
- **Where lower-level modules live.** NixOS, home-manager and darwin modules "are stored as option
  values in the top-level configuration". Their `deferredModule` type merges values, so
  "multiple lower-level module values [can] merge under one distinct name".
- **Benefits it claims:** the type of every file is known, automatic importing (it names
  import-tree), and file path independence ("each file can be freely renamed and moved").
- **Anti-patterns, as listed in the README:**
  1. _Not declaring options._ "Using _only_ existing options (such as flake-parts'
     `flake.modules`) ... prevents us from translating our mental model". The author recommends
     declaring your own `deferredModule` options. In 2026-06 the README examples were changed from
     `flake.modules.nixos.audio` to `nixos.modules.audio` (commit `c93612e`).
  2. _`specialArgs` pass-thru._ Every file can read and write the top-level `config`, so values
     need not be injected via `specialArgs` or `extraSpecialArgs`.
  3. _Lower-level module name proliferation._ One named module per feature makes "`imports` lists
     ... much longer than necessary", and every new module "would have to be added to all of the
     import lists". The advice is: "Consider merging multiple non-distinct lower-level modules
     under one distinct name."
  4. _Fanaticism._ "Use it where it fits and make exceptions where appropriate". `callPackage`
     files may sit among the modules if excluded from auto-import; suggested suffix `.pkg.nix`.
  5. _`enable` options._ "In most cases, importing a module should enable the feature that it
     provides" (added 2026-07-02, commit `586e113`).
- **Required skills, as stated:** the Nix language, the module system, and `deferredModule`.
- **Relationship to other projects.** The README now lists third-party configs under "Other
  examples, for which the author cannot vouch". On 2026-06-23 (commit `631dc19`) its "See also"
  links to den, dendrix and Doc-Steve's guide were removed.

**The author's own config, [infra] (`49d9260`, NixOS only).** Its main structural choices:

- **Few named modules.** It declares `nixos.modules.base` and `pc`, plus `efi` and `zfs`, and
  `homeManager.modules.base` and `gui`. Feature files merge into these, for example
  `modules/mightyiam/git/basics.nix` writes `home.base.programs.git` [infra-git]. `pc` extends
  `base` via `deferredModuleWith { staticModules = [ base ]; }` [infra-pc].
- **Hosts.** A `nixos.configurations.<name>.module` option calls `eval-config.nix` and is mapped
  into `flake.nixosConfigurations` and `flake.checks` [infra-nixos]. A host file such as
  `fawkes.nix` sets `system.stateVersion` and imports `[efi zfs pc]` plus `config.users.bow.nixos.pc`
  [infra-fawkes].
- **Users** are a `users.<name>` option with `nixos.{base,pc}` and `home.{base,gui}`
  deferredModules. The user's NixOS module sets `home-manager.users.${name} = home.base`
  [infra-users].
- **home-manager stateVersion** comes from a shared module:
  `home.stateVersion = osConfig.system.stateVersion` [infra-hm].
- **pkgs** is built in `perSystem`, and NixOS gets it via
  `nixpkgs.pkgs = withSystem <system> (getAttr "pkgs")` [infra-nixpkgs].
- **Auto-import** uses `(import-tree).filterNot (hasSuffix ".pkg.nix") ./modules` [infra-outputs].
- **Keys.** Every named module gets an explicit `key` via `apply` [infra-base].

---

## 3. Options compared

|                           | **flake-parts + import-tree (plain)**                                                                                                                 | **den**                                                                                                                                                                                                                       | **flake-aspects**                                                                                                                          |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| What it adds              | `flake.modules.<class>.<name>` (deferredModule, `_class`-checked) [fp-modules.nix]; `withSystem`/`perSystem` [fp-args]; recursive import [it-default] | Entities (host/user/home), Aspects (functions of context returning multi-class config), Policies, Quirks; `den.hosts.<system>.<name>.users.<u>` registry auto-producing `nixos/darwinConfigurations` [den-readme] [den-hosts] | Transposes `flake.aspects.<aspect>.<class>` into `flake.modules.<class>.<aspect>`, plus `includes`/`provides` dependency graph [fa-readme] |
| Concepts to learn         | Module system, deferredModule, flake-parts                                                                                                            | Above, plus entity/aspect/policy/quirk/schema/context pipeline                                                                                                                                                                | Above, plus transposition and aspect includes                                                                                              |
| Cross-class features      | Manual: one file sets several classes; HM half wired via `sharedModules` or `users.<u>.imports`                                                       | Native: one aspect returns `nixos`/`darwin`/`homeManager`; HM forwarded into `home-manager.users.<u>` automatically [den-hm]                                                                                                  | Native grouping by aspect; wiring still yours                                                                                              |
| Host↔user                 | Your code                                                                                                                                             | Bidirectional via policies [den-readme]                                                                                                                                                                                       | Not addressed                                                                                                                              |
| Darwin                    | nix-darwin `flakeModules.default` declares `flake.darwinConfigurations` [nd-flake-module]                                                             | Yes (class auto-detected from system; `brew.apps`) [den-hosts]                                                                                                                                                                | Class-agnostic                                                                                                                             |
| Maturity                  | flake-parts: 1.5k stars, active (last commit 2026-10-01), no tags. import-tree v0.3.0 (2026-09-03), moved to `denful/import-tree` [gh-meta]           | v0.19.0 (2026-09-24); 19 releases in 12 months, 7 with breaking notes; `den.ctx` deprecated [den-migrate]; "v0.x means ... fast-paced, evolving" [den-releases]                                                               | v0.7.0 (2026-03-13), 72 stars, last push 2026-08-31; den now "bundles its own aspect types ... optimized for Den" [den-releases]           |
| Pattern author's stance   | Pattern was designed on it                                                                                                                            | README: den "no longer relates to the Dendritic name" [den-readme]                                                                                                                                                            | n/a                                                                                                                                        |
| Fit for 1 non-expert user | **Best.** Smallest surface; every behaviour is visible in your files                                                                                  | Poor: large conceptual surface, high churn, upstream author has moved on [vix-ren]                                                                                                                                            | Marginal: saves a little typing, adds a dependency                                                                                         |

Others noted, not evaluated in depth:

- **dendrix** [dendrix]: a community index and "distribution". Last push 2026-01-27, and it calls
  itself "an on-going effort". Use it only as a list of example repos.
- **Unify** (quasigod): cited in den's README as a predecessor. Not checked.
- **Doc-Steve's guide** [ds-readme]: a design guide by a community member, not by the pattern
  author. It was linked from the dendritic README until 2026-06. It is useful for patterns
  (Simple, Multi-Context, Inheritance, Collector, Factory), but it states: "For users solely
  relying on Nix to run a single machine, this guide may be overly detailed."

---

## 4. Patterns observed in real configs

Sample: configs that have darwin, NixOS and home-manager integrated, plus the author's config.

| Repo (pinned)                                           | Classes                            | Compose                                                                                                                     | Build hosts                                                                                                                                             | HM wiring                                                                                                               | pkgs / unstable                                                                                          | HM stateVersion                                                                                      | Layout                                                                                                           |
| ------------------------------------------------------- | ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **AlexNabokikh/nix-config** [alex]                      | darwin, nixos, HM                  | Named per-feature modules aggregated in `base` bundles per class; hosts import `base` + few extras                          | Thin option `configurations.{nixos,darwin}.<name>.module` → `mapAttrs nixosSystem/darwinSystem` + `checks` [alex-configs]                               | `generic.homeManagerIntegration`: `useGlobalPkgs`, `sharedModules = [ homeManager.base ]` [alex-base]                   | single `nixos-unstable`                                                                                  | constant `"26.05"` via `home-manager.users.${config.primaryUser}` in a generic module [alex-phome]   | `modules/hosts/<h>/default.nix` + `_hardware.nix`, `modules/programs/*.nix`, `modules/darwin/`, `modules/nixos/` |
| **MatthiasBenaets/nix-config** [matthias]               | darwin, nixos, HM                  | Collector `base` (git, users, HM, nixpkgs merge into `nixos.base`/`darwin.base`) + named optional features imported by host | Direct `flake.darwinConfigurations.m1 = darwinSystem {…}` in host file; declares `flake.darwinConfigurations` option itself [matthias-fp] [matthias-m1] | In `base`; host adds `home-manager.users.<u>.imports`                                                                   | perSystem pkgs with `stable`/`master` overlays, fed via `withSystem` → `nixpkgs.pkgs` [matthias-nixpkgs] | per host via `host.state.version` passed through `extraSpecialArgs` (the anti-pattern) [matthias-hm] | `modules/hosts/{darwin,nixos}/<h>/`, `modules/programs/`, `modules/general/`                                     |
| **Doc-Steve example** [ds-example]                      | darwin, nixos, HM                  | Named features + Inheritance bundles (`system-desktop` imports `system-cli`…)                                               | `flake.lib.mkDarwin "aarch64-darwin" "macbook"` helper; declares `darwinConfigurations` option [ds-darwinfix] [ds-lib]                                  | `nixos/darwin.home-manager` modules; user factory sets `home-manager.users.<u>.imports = [ homeManager.<u> ]` [ds-user] | default                                                                                                  | not shown                                                                                            | `modules/hosts/<h> [D]/`, `modules/factory/`, `modules/nix/tools/`                                               |
| **mightyiam/infra** [infra]                             | nixos, HM                          | Few collectors (`base`, `pc`, `gui`) — features merge in                                                                    | Custom `nixos.configurations` option                                                                                                                    | `users.<u>.nixos.base` sets `home-manager.users.<u>`                                                                    | perSystem + `withSystem`                                                                                 | `osConfig.system.stateVersion`                                                                       | `modules/<topic>/…`, `modules/computers/<h>.nix`, `modules/<user>/…`                                             |
| **thursdaddy/nixos-config** [thurs]                     | darwin, nixos                      | Merges into a few names (`apps`, `base`, `desktop`, `dev`), still uses `enable` flags (`mine.*`)                            | `configurations.darwin.mbp.module` + per-host `darwinSystem.nix`; passes `specialArgs.lib` [thurs-mbp]                                                  | n/a                                                                                                                     | stable `nixos-26.05` + `unstable` input, `nix-darwin-26.05`                                              | n/a                                                                                                  | `modules/hosts/<h>/{config,imports,darwinSystem}.nix`                                                            |
| **GaetanLepage/nix-config** (listed by author) [gaetan] | nixos, HM (darwin = standalone HM) | Named + `core` bundles                                                                                                      | `nixosHosts.<h>` registry option with `specialArgs` [gaetan-nixos]                                                                                      | `homeManagerModules` list → `home-manager.users.${primaryUser}.imports`                                                 | per-host `unstable` bool selects input                                                                   | constant `"24.11"`                                                                                   | `modules/hosts/<h>/default.nix` + `_nixos/`, `_home/`                                                            |

Cross-cutting observations (facts from the table, synthesis is **Assessment**):

- **Composition.** Every sample composes by import. Only thursdaddy also keeps `enable` flags.
  The two most-starred darwin configs (Alex, Matthias) use a `base` collector or bundle so that
  hosts import 2-10 modules, not dozens.
- **Building hosts.** Four of the six use a thin per-class host option (`configurations.<class>.<name>.module`
  or similar). It came from the author's example, and kriswill's `modules/darwin.nix` says it was
  "Adapted from the mightyiam/dendritic example" [kris-darwin]. Two build hosts directly.
  Everyone who builds `darwinConfigurations` from multiple places first declares that option.
- **HM wiring.** HM always runs as a NixOS or darwin module, with `useGlobalPkgs` and
  `useUserPackages`. HM modules reach users through `sharedModules` or
  `home-manager.users.<u>.imports` set from a system-class module, never as a separate
  host-level import of each HM feature.
- **stateVersion.** No consistent convention. Options seen: constant, `osConfig`-derived
  (NixOS only), or per host.
- **Hardware files** are `_`-prefixed and imported by relative path (Alex, Gaetan).

---

## 5. Evaluation of each draft decision

| #   | Draft decision                                                                                                                  | Verdict                   | Evidence / reasoning                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| --- | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D1  | flake-parts + import-tree; `flake.modules.<class>.<name>`, classes `darwin`/`nixos`/`homeManager`                               | **Keep** (caveat)         | Class names match what each evaluator checks: HM `class = "homeManager"` [hm-default#L32], nix-darwin `class = "darwin"` [nd-eval#L81]; mismatch is rejected [nixpkgs-modules#L456]. `flake.modules` sets `_class`, so wrong-class imports error clearly [fp-modules.nix#L25]. Caveat: the author now prefers declaring your own options over relying _only_ on `flake.modules` [dendritic#not-declaring-options]. **Assessment:** `flake.modules` is fine for one user; add your own options only when you need typed structure such as a `deferredModuleWith` base.                                                                                                                         |
| D2  | HM as nixos/darwin module                                                                                                       | **Keep**                  | Universal in sample (§4); gives `osConfig` [hm-common#L30].                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| D3  | Stable 26.05 + unstable overlay                                                                                                 | **Keep** (caveat)         | Match branches: `nix-darwin-26.05` with `nixpkgs-26.05-darwin`, as nix-darwin's README says [nd-readme], and HM `release-26.05` [hm-branches]. Put the overlay in `nixpkgs.overlays` inside `base` and set `useGlobalPkgs = true`, so HM uses "the system configuration's `pkgs`" [hm-common#L95]. **Assessment:** a single NixOS input `nixos-26.05` plus a darwin input `nixpkgs-26.05-darwin` means two stable inputs. One input for both also works (thursdaddy uses `nixos-26.05` for darwin), but it departs from nix-darwin's guidance.                                                                                                                                                |
| D4  | Import = enable; no enable flags                                                                                                | **Keep**                  | The author's anti-pattern list [dendritic#enable-options].                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| D5  | No central registry option, no evaluator                                                                                        | **Keep** (caveat)         | The failed design's evaluator and genAttrs-over-profiles are absent from every sample. A thin `configurations.<class>.<host>.module` option is _not_ a registry of features. It is what the author and most samples use, and it gives a `checks` output for free [infra-nixos] [alex-configs]. **Assessment:** optional; adopt it if you want `nix flake check` to build every host.                                                                                                                                                                                                                                                                                                          |
| D6  | Host file defines `flake.darwinConfigurations.<h> = darwinSystem { modules = [ self.modules.darwin.<h> ]; }`                    | **Keep + required fix**   | flake-parts' `flake` freeform type is `lazyAttrsOf (unique raw)` [fp-flake.nix#L14]. Two files each defining one darwin host fail with "No option has been declared for this flake output attribute". Import `inputs.nix-darwin.flakeModules.default`, which declares `lazyAttrsOf raw` (added 2025-12-28, present on `nix-darwin-26.05`) [nd-flake-module]. `nixosConfigurations` is already declared by flake-parts [fp-nixoscfg]. Minor: prefer `config.flake.modules` over `self.modules`, which does not need flake `self` (the author's removed example used `config.flake.modules`).                                                                                                   |
| D7  | `base` module every host imports                                                                                                | **Keep, expand its role** | Used by Alex, Matthias and mightyiam. Make it a _collector_: always-on features write into `flake.modules.{darwin,nixos,homeManager}.base` directly, so they need no import line at all (the "Collector Aspect" [ds-aspects]; Matthias's `git.nix` [matthias]).                                                                                                                                                                                                                                                                                                                                                                                                                               |
| D8  | Tiny `mkDarwin`/`mkNixos` helper later                                                                                          | **Keep**                  | Doc-Steve does exactly this, as a plain function [ds-lib]. Fits ADR 0001.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| D9  | User module defines `darwin.ety`, `nixos.ety`, `homeManager.ety`                                                                | **Keep**                  | Same shape as Doc-Steve's user factory [ds-user] and mightyiam's `users.<u>` [infra-users]. Have `darwin.ety` and `nixos.ety` set `home-manager.users.ety.imports = [ homeManager.ety ]`, so a host imports only `darwin.ety`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| D10 | User imports both the system half and the HM half of each feature (two imports)                                                 | **Change**                | Across darwin and nixos this is up to _three_ lines per feature, the "name proliferation" cost the author warns against [dendritic#proliferation]. Only Gaetan does something similar: the host lists `desktop` in both `modules` and `homeManagerModules` [gaetan]. The others avoid it with bundles or `sharedModules`. Alternatives: (a) a feature's system half adds `home-manager.sharedModules = [ config.flake.modules.homeManager.<f> ]` [ds-aspects], so one import per class brings both halves; (b) always-on features merge into `base` (D7). **Assessment:** with one user, `sharedModules` ("applies to all users on this host") is harmless. Revisit if a second user appears. |
| D11 | Host sets `home-manager.users.ety.home.stateVersion`                                                                            | **Keep** (alt.)           | Works, because `users.<name>` merges as a submodule. Alternative without the username: `home-manager.sharedModules = [{ home.stateVersion = "26.05"; }]` in the host. `osConfig.system.stateVersion` [infra-hm] works on NixOS only, because nix-darwin's `system.stateVersion` is an integer (e.g. `6`) [alex-mac] [matthias-m1].                                                                                                                                                                                                                                                                                                                                                            |
| D12 | Host/User/Feature responsibilities                                                                                              | **Keep** (caveat)         | Homebrew casks are nix-darwin _system_ options, and homebrew needs `system.primaryUser`, which defaults `homebrew.user` [nd-homebrew]. So "User = homebrew casks" means `darwin.ety` sets `homebrew.casks` and `system.primaryUser = "ety"`. That is fine, but the darwin host must import `darwin.ety`.                                                                                                                                                                                                                                                                                                                                                                                      |
| D13 | Bundles only when duplication appears; additive                                                                                 | **Keep**                  | Matches "merge ... under one distinct name" [dendritic#proliferation] and mightyiam's `pc` ⊇ `base` via `deferredModuleWith` [infra-pc]. Caveat: diamond imports. See pitfall P3.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| D14 | Layout `modules/flake/`, `modules/features/<f>.nix`, `modules/hosts/<h>/default.nix` + `_hardware.nix`, `modules/users/<u>.nix` | **Keep**                  | Nearly identical to Alex's layout [alex]. `_hardware.nix` is skipped by import-tree because its relative path contains `/_` [it-default#L64] [it-default#L85]. Import it by path from the host's nixos module. Also add `.filterNot (lib.hasSuffix ".pkg.nix")` if you keep callPackage files in the tree [infra-outputs]. **Assessment:** `features/` is optional; the author groups by topic (`audio/`, `shell/`) without a `features/` level.                                                                                                                                                                                                                                              |
| D15 | helios (aarch64-darwin), typhon (x86_64-linux stub)                                                                             | **Keep**                  | Set `nixpkgs.hostPlatform` in the host module, as Alex and Doc-Steve do. A stub NixOS host needs `fileSystems."/"` and a boot loader, or it fails to evaluate: **Assessment**, standard NixOS assertions.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| D16 | Avoid specialArgs/hostProfiles                                                                                                  | **Keep**                  | Anti-pattern per author [dendritic#specialargs-pass-thru]. Read host facts from the inner `config` (e.g. `config.networking.hostName`, `osConfig` in HM). Read flake values from the outer top-level `config` by closure.                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |

---

## 6. Pitfalls checklist

- [ ] **P1. darwinConfigurations merge error.** Import `inputs.nix-darwin.flakeModules.default`
      [nd-flake-module] [fp-flake.nix#L14].
- [ ] **P2. `flake-parts.flakeModules.modules` not imported.** In dendritic discussion #24, a
      confusing infinite-recursion trace went away once it was imported [disc-24].
- [ ] **P3. No `key` means no deduplication.** Importing the same `flake.modules.*.x` via two
      paths (bundle plus direct, or `sharedModules` plus user imports) applies it twice. List
      definitions duplicate, and any `options` it declares error as already declared.
      Open issues: [fp#299], [nixpkgs#340361]. The author's discussion #25 points to the same fix
      [disc-25]. Doc-Steve also warns about Multi-Context combined with Inheritance [ds-aspects].
      Mitigations: one import path per module; or wrap the module as `{ key = "darwin.git"; imports = [ … ]; }`,
      as [infra-base] does via `apply`.
- [ ] **P4. Imports cannot depend on `config`.** Doc-Steve: "Imports must not be conditional"
      [ds-basics]. Put the condition inside the module's content instead.
- [ ] **P5. Outer vs inner `config` shadowing.** In `{ config, ... }: { flake.modules.darwin.x = { config, ... }: … }`
      the inner `config` is darwin's. Bind outer values with `let` or `inherit (config.flake.modules) …`
      at the top, or name the inner args (`darwinArgs@{…}`), as mightyiam does [infra-nixpkgs] [infra-users].
- [ ] **P6. specialArgs creep.** Includes `extraSpecialArgs` for HM [dendritic#specialargs-pass-thru].
      `osConfig` is supplied by HM itself [hm-common#L30].
- [ ] **P7. Untracked files invisible.** In a git flake, files must be `git add`ed. This is flakes
      behaviour, not import-tree's [nix-flake-ref]. import-tree just calls `builtins.readDir` [it-default#L152].
- [ ] **P8. `_` ignores whole subtrees.** The filter is "path contains `/_`", relative to the tree
      root, so `_wip/` hides everything under it [it-default#L64]. Explicitly listed files bypass the
      filter [it-default].
- [ ] **P9. Non-module `.nix` files under `modules/`** (callPackage files, `_hardware.nix`) must
      be `_`-prefixed or filtered [dendritic#fanaticism].
- [ ] **P10. deferredModule merging is silent.** Two files defining `flake.modules.darwin.git`
      merge rather than collide. That is useful (collector), but typos in names create new modules
      instead of errors. **Assessment.**
- [ ] **P11. Class mismatch.** `_class` checking catches importing `homeManager.x` into darwin
      [nixpkgs-modules#L456]. The `generic` class is unchecked [fp-modules.nix]. Use `generic` only
      for content valid in every class that imports it (Alex's `generic.homeManagerIntegration`
      [alex-base]).
- [ ] **P12. Branch mismatch** between nixpkgs, nix-darwin and HM release branches [nd-readme].
- [ ] **P13. stateVersion type differs.** darwin `system.stateVersion` is an int; HM's
      `home.stateVersion` is a string like "26.05" (D11).
- [ ] **P14. Repo moves.** `vic/import-tree` now redirects to `denful/import-tree` [gh-meta].
      Prefer the canonical URL in `flake.nix`.

---

## 7. Open questions / not verified

- Whether flake-parts will merge a default `key` for `flake.modules` ([fp#299] has been open
  since 2025 with a one-line patch proposed). If merged, P3 mostly disappears.
- nixpkgs PR #431169 (author's "split flake into module system") is closed, unmerged. There is
  still no upstream `configurations` option, so each config defines its own [disc-3].
- Unify (codeberg quasigod/unify) and `ren` (vic/ren, 1 star, 1 week old) were not evaluated.
- Binary-cache coverage of `nixos-26.05` vs `nixpkgs-26.05-darwin` for aarch64-darwin was not
  measured. Rely on nix-darwin's README recommendation.
- No sample config was evaluated locally. Table rows are read from source, not run.
- Doc-Steve's wiki was read via a summariser (WebFetch); code snippets were cross-checked
  against the repo's example files.

---

## 8. Sources

Pattern

- [dendritic-readme] https://github.com/mightyiam/dendritic/blob/6c76240658cf1c840faad557c0e0726064170a65/README.md
  (anchors: `#not-declaring-options`, `#specialargs-pass-thru`, `#lower-level-module-name-proliferation`, `#fanaticism`, `#enable-options`). Commit history: https://github.com/mightyiam/dendritic/commits/master (c93612e, 631dc19, 586e113).
- [disc-3] https://github.com/mightyiam/dendritic/discussions/3 · [disc-24] …/discussions/24 · [disc-25] …/discussions/25 · …/discussions/11 (osConfig)

Author's config: mightyiam/infra @ `49d9260f2d13ebc811cb484c6c9e991b971c5008`

- [infra] https://github.com/mightyiam/infra/tree/49d9260f2d13ebc811cb484c6c9e991b971c5008
- [infra-outputs] …/blob/49d9260f2d13ebc811cb484c6c9e991b971c5008/outputs.nix
- [infra-nixos] …/modules/nixos.nix · [infra-base] …/modules/nixos/base.nix · [infra-pc] …/modules/nixos/pc.nix
- [infra-hm] …/modules/home-manager.nix · [infra-users] …/modules/users.nix · [infra-nixpkgs] …/modules/nixpkgs.nix
- [infra-fawkes] …/modules/computers/fawkes.nix · [infra-git] …/modules/mightyiam/git/basics.nix

flake-parts @ `024633cd702b10285db5cb19b40ad48d2399ba60`

- [fp-modules.nix] https://github.com/hercules-ci/flake-parts/blob/024633cd702b10285db5cb19b40ad48d2399ba60/extras/modules.nix (L24 `TODO: set key?`, L25 `_class`)
- [fp-flake.nix] …/modules/flake.nix#L14 · [fp-nixoscfg] …/modules/nixosConfigurations.nix
- [fp-args] https://flake.parts/module-arguments.html · https://flake.parts/options/flake-parts-modules.html
- [fp#299] https://github.com/hercules-ci/flake-parts/issues/299

import-tree @ `eb1b52eaecc57f7c136d07ae8a93e724dfecac46`

- [it-default] https://github.com/denful/import-tree/blob/eb1b52eaecc57f7c136d07ae8a93e724dfecac46/default.nix (L64 filter, L85 relativize, L152 readDir)
- https://github.com/denful/import-tree/blob/eb1b52eaecc57f7c136d07ae8a93e724dfecac46/docs/src/content/docs/guides/filtering.mdx

den / flake-aspects / dendrix

- [den-readme] https://github.com/denful/den/blob/0f7675b0b789eabe1a62f8a31b5323a7ad3ca5c4/README.md
- [den-hosts] …/docs/src/content/docs/guides/declare-hosts.mdx · [den-hm] …/guides/home-manager.mdx
- [den-releases] …/docs/src/content/docs/releases.mdx · [den-migrate] …/guides/migrate-ctx.mdx · https://github.com/denful/den/releases
- [vix-ren] https://github.com/vic/vix/blob/7cdc0be0162518d70882d0a941fe0927428143e6/flake.nix (commit d36c86be "ren", 2026-10-22); https://github.com/vic/ren
- [fa-readme] https://github.com/denful/flake-aspects/blob/e5bbf7be955e8289d545c783673808b18d48c780/README.md
- [dendrix] https://github.com/denful/dendrix/blob/ffea5e597bd1c5f8d35d51545c67cff984a0ff40/README.md

Doc-Steve guide @ `69edacdb5a4a6ca71d649bb8eb62cf8c630c8627`

- [ds-readme] https://github.com/Doc-Steve/dendritic-design-with-flake-parts/blob/69edacdb5a4a6ca71d649bb8eb62cf8c630c8627/README.md
- [ds-basics] https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Basics · [ds-aspects] …/wiki/Dendritic_Aspects
- [ds-example] …/tree/69edacdb5a4a6ca71d649bb8eb62cf8c630c8627/modules
- [ds-darwinfix] …/blob/69edacdb…/modules/nix/flake-parts%20%5B%5D/darwinConfigurations-fix.nix
- [ds-lib] …/blob/69edacdb…/modules/nix/flake-parts%20%5B%5D/lib.nix
- [ds-user] …/blob/69edacdb…/modules/factory/user%20%5BND%5D/user.nix

Real-world configs

- [alex] https://github.com/AlexNabokikh/nix-config/tree/e4981729fda81c552b83ee43c809eef6bccda221 — [alex-configs] `modules/configurations/default.nix`, [alex-base] `modules/base.nix`, [alex-phome] `modules/profile/primary-user-home.nix`, [alex-mac] `modules/hosts/work-mac.nix`
- [matthias] https://github.com/MatthiasBenaets/nix-config/tree/d2123cc4d72795024cfdddac8a6a2528f434a115 — [matthias-fp] `modules/general/flake-parts.nix`, [matthias-m1] `modules/hosts/darwin/m1/default.nix`, [matthias-hm] `modules/hosts/home-manager.nix`, [matthias-nixpkgs] `modules/general/nixpkgs.nix`
- [thurs] https://github.com/thursdaddy/nixos-config/tree/b0e6ed285069f62a1d6e711e5c2afcbca8a2eb6d — [thurs-mbp] `modules/hosts/mbp/darwinSystem.nix`
- [gaetan] https://github.com/GaetanLepage/nix-config/tree/2dd33001a1a812d62db84e1ce57c39529bc91d6c — [gaetan-nixos] `modules/flake/hosts/nixos.nix`
- [kris-darwin] https://github.com/kriswill/dotfiles/blob/7bea4a172cdd2873f6e05f8700fda3680dba6a88/modules/darwin.nix

Upstream tools

- [nd-flake-module] https://github.com/nix-darwin/nix-darwin/blob/d31953cf55f9027a56e9be938daf5db8c5655663/flake-module.nix (added in 3ab1648f501cc7f2b42b60b2218ccfa10a4280d0)
- [nd-readme] https://github.com/nix-darwin/nix-darwin/blob/d31953cf55f9027a56e9be938daf5db8c5655663/README.md (L63-65)
- [nd-homebrew] https://github.com/nix-darwin/nix-darwin/blob/d31953cf55f9027a56e9be938daf5db8c5655663/modules/homebrew.nix (L683, L948)
- [hm-common] https://github.com/nix-community/home-manager/blob/c216bf5a1f173b0481bd5c8c489ebe5595ecc68c/nixos/common.nix (L30 osConfig, L95 useGlobalPkgs, L144 sharedModules)
- [hm-default] https://github.com/nix-community/home-manager/blob/c216bf5a1f173b0481bd5c8c489ebe5595ecc68c/modules/default.nix (L32)
- [nd-eval] https://github.com/nix-darwin/nix-darwin/blob/d31953cf55f9027a56e9be938daf5db8c5655663/eval-config.nix (L81)
- [hm-branches] https://github.com/nix-community/home-manager/tree/release-26.05
- [nixpkgs-modules] https://github.com/NixOS/nixpkgs/blob/1f607aa79b6356ed45d3cd3c8079c196e79efa2c/lib/modules.nix (L456 class check, L536 anon key, L676 key)
- [nixpkgs#340361] https://github.com/NixOS/nixpkgs/issues/340361
- [nix-flake-ref] https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake.html ("files are fetched … as long as they have been added to the Git repository")
- [gh-meta] `gh api repos/<owner>/<repo>` on 2026-10-26 (stars, `pushed_at`, redirects `vic/*` to `denful/*`)
