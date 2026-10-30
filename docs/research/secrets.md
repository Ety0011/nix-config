# Secrets: what to use, where it goes, what stays out

Research date: 2026-10-28. Method: each candidate's own repo was cloned at the commit given in §11
and its modules and CLI source were read; claims were followed to the code that owns them (sops,
age, sops-nix, agenix, home-manager, nixpkgs). Package versions come from this flake's locked
`nixpkgs-26.05-darwin` @ `d592aacecd35` [lock]. A few claims were tested on helios in a scratch
directory with throwaway keys, and nothing in the config was changed [local]. Stars and push dates
come from `gh api repos/<owner>/<repo>` on 2026-10-28 [gh-meta]. "Fact" statements carry a
citation; **Assessment** marks my judgement. This revisits best-of-nix §4.2 (see §10). Familiarity
was not used as a reason for any pick.

---

## 1. TL;DR

- **Pick: sops-nix, system-level modules only (nix-darwin and NixOS), with native post-quantum age
  keys. No Home Manager module and no SSH-derived keys.** Reasons, all on merit:
  1. On darwin it keeps decrypted secrets on a RAM disk, for both system and user installs. On
     darwin, agenix's Home Manager module writes them to a normal folder on disk [sops-darwin-go]
     [agenix-hm] [local].
  2. The install is all-or-nothing. Every secret is decrypted before one atomic symlink swap, so a
     failed decrypt keeps the previous secrets [sops-main].
  3. `nix flake check` fails if a declared secret is missing from its file. This needs no key, so
     it also works in public CI [sops-readme].
  4. It has templates, for config files with a secret inside [sops-readme]. `sops` 3.13.3 is in
     nixpkgs; the agenix CLI is not [lock].
  5. It has one flake input with one `follows` [sops-flake].
- **Use native `age-keygen -pq` keys, not `ssh-to-age`.** The repo is public, so every ciphertext
  stays public forever in git history. Only hybrid ML-KEM keys resist "collect now, decrypt later"
  [age-1.3.0]. SSH Ed25519 keys are classic keys. A key tied to the SSH key would also break if you
  add a passphrase to it, which features.md §4.7 suggests [sops-readme].
- **Three keys:** `helios` (a file in `~/Library/Application Support/sops/age/`), `recovery` (its
  private half kept only in Apple Passwords) and later `typhon` (`/var/lib/sops-nix/key.txt`). Every
  file is encrypted to all three. Do not add the helios key to backup-home: like SSH keys, it is
  per device. The recovery key is what gets you back in.
- **What changes now:** nothing has to. helios has one real candidate, the NAS password in the
  unmanaged `~/.config/rclone/rclone.conf` [local]. Moving it into sops is optional, and worth it
  because a fresh Mac could then restore its backups from git plus the recovery key (§7). The real
  trigger is typhon (password hash, restic, Syncthing).
- **Keep out of sops:** the gh token (already in the macOS keychain [local]), SSH private keys,
  the SSH key passphrase (Keychain), typhon's LUKS passphrase, Tailscale and app logins, macOS
  Wi-Fi, and per-project `.envrc` tokens (§8).
- **Runner-up: agenix.** It is smaller, easier to audit, and age refuses to mix PQ and classic
  recipients in one file [age-go]. It wins if every secret is a whole file, you never need
  templates, and no secret is consumed by Home Manager on darwin. Its darwin HM agent has an open
  restart-loop bug at HEAD [agenix-372].
- **Sticky:** the file format, `.sops.yaml` and the key layout are hard to change later, so write
  `docs/adr/0005-secrets.md` before the first secret.

---

## 2. What secrets exist in this config

Inventory from `modules/` at `61ae255` and from helios [local].

| Secret                                             | Host   | Today                                                                                                 | Belongs in sops?                                           |
| -------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| NAS login for rclone (`i14-nas`: host, user, pass) | helios | unmanaged `~/.config/rclone/rclone.conf`, "credentials stay in the unmanaged" file [backup-home#L1-3] | **Optional now.** It is what makes backups restorable (§7) |
| gh OAuth token                                     | both   | macOS keychain: `gh auth status` says "(keyring)" [local]                                             | No (§8)                                                    |
| git HTTPS credentials                              | both   | gh credential helper [gh.nix]                                                                         | No                                                         |
| `~/.ssh/id_ed25519`                                | helios | no passphrase [features#L67]; per device [backup-home#L56-59]                                         | No                                                         |
| typhon `ety` password hash                         | typhon | none yet; blocks login [features#L23-24] [features#L413-422]                                          | **Yes** (`neededForUsers`)                                 |
| typhon LUKS passphrase                             | typhon | typed at boot; `/tmp/secret.key` at install [adr-0002#L13]                                            | No                                                         |
| restic password + repo creds                       | typhon | not yet [features#L443-444]                                                                           | Yes, when triggered                                        |
| Syncthing device cert/key                          | both   | not yet [features#L461-464]                                                                           | Yes, if you want stable device IDs                         |
| Wi-Fi PSK                                          | typhon | not yet                                                                                               | Only if typhon uses Wi-Fi                                  |
| API tokens in project `.envrc`                     | helios | untracked files under `~/Documents` [features#L60-61]                                                 | No (outside this repo)                                     |
| plaintext password in `~/.zsh_history`             | helios | [features#L71]                                                                                        | No: delete it and change that password                     |

---

## 3. Candidates and activity

Fact, from [gh-meta] on 2026-10-28:

| Project                   | Stars                  | Last push                    | Latest release/tag  | darwin                             | HM   | NixOS |
| ------------------------- | ---------------------- | ---------------------------- | ------------------- | ---------------------------------- | ---- | ----- |
| Mic92/sops-nix            | 3249                   | 2026-10-26                   | none (rolling)      | yes                                | yes  | yes   |
| ryantm/agenix             | 2525                   | 2026-10-20                   | 0.18.0 (2026-09-27) | yes                                | yes  | yes   |
| yaxitech/ragenix          | 483                    | 2026-10-25 (HEAD 2025-10-30) | 2025.03.09          | modules passed through from agenix | same | same  |
| oddlama/agenix-rekey      | 447                    | 2026-10-09                   | none                | yes                                | yes  | yes   |
| clan-lol/clan-core (vars) | 181 (read-only mirror) | 2026-10-26                   | —                   | "update" + vars only               | —    | yes   |
| brizzbuzz/opnix           | 190                    | 2026-08-18                   | v0.11.0             | yes                                | yes  | yes   |
| milieuim/vaultix          | 147                    | 2026-10-04                   | v0.3.0 (2025-05-05) | no                                 | no   | yes   |
| AGWA/git-crypt            | 9973                   | 2025-09-24                   | 0.8.0               | n/a                                | n/a  | n/a   |
| getsops/sops (CLI)        | 23544                  | 2026-10-27                   | v3.13.3             |                                    |      |       |
| FiloSottile/age           | 24094                  | 2026-08-29                   | v1.3.2              |                                    |      |       |

- **sops-nix:** decrypts sops files (YAML/JSON/dotenv/INI/binary) at activation, "one secret per
  file" with owner and mode [sops-readme#L7-30]. Modules: `nixosModules.sops`,
  `darwinModules.sops`, `homeManagerModules.sops` [sops-flake#L63-82]. Its only flake input is
  `nixpkgs` [sops-flake#L3]. The binary `sops-install-secrets` is a Go program built from your
  `pkgs` (`buildGoModule`), not a nixpkgs package [sops-darwin#L258-265] [sops-pkg]. It uses
  `getsops/sops` v3.13.3 as a library [sops-gomod].
- **agenix:** "encrypts secrets with SSH public keys", one `.age` file per secret, CLI
  `agenix -e/-r/-c` [agenix-readme] [agenix-ref#L334-374]. The rules file is now
  `agenix-rules.nix`; `secrets.nix` still works with a warning and "will be removed"
  [agenix-ref#L376-380]. Its only flake input is `nixpkgs` [agenix-flake#L4-6]. The `agenix`
  CLI is **not** in nixpkgs (only `ragenix` is) [lock], so it comes from the flake.
- **ragenix:** a Rust CLI drop-in for agenix. Its modules are agenix's, passed through
  [ragenix-flake#L366-367]. It adds rust-overlay, crane and flake-utils inputs
  [ragenix-flake#L5-14]. No tag since 2025-03-09.
- **agenix-rekey:** a single master identity (YubiKey/FIDO2/age), automatic per-host rekeying,
  and secret **generators** [rekey-readme#L1-33]. It has NixOS, darwin and HM modules
  [rekey-flake#L60-72], and several dev inputs (devshell, flake-compat, pre-commit-hooks,
  treefmt-nix) [rekey-flake#L2-21]. It warns that in its `local` mode "if your repository is
  public and one of your hosts is compromised, an attacker may decrypt any secret that was ever
  encrypted for that host. This includes secrets that are in the git history"
  [rekey-readme#L829-835].
- **clan vars:** generators plus encrypted storage under `vars/per-machine/…`, with an age or
  sops backend, driven by the `clan` CLI and clan's inventory [clan-vars-intro]
  [clan-vars-age]. macOS support is "`clan machines update` … [and] vars" [clan-macos].
- **opnix:** pulls secrets from 1Password at activation, using a service-account token stored in
  a file (`tokenFile = "/etc/opnix-token"`) [opnix-readme#L56-60].
- **vaultix:** "Secret managing scheme for NixOS" [vaultix-readme]. No darwin.
- **git-crypt / git-agecrypt:** transparent encryption in git. sops-nix suggests them only for
  secrets needed _at evaluation time_ [sops-readme#L1008-1016].
- **Built-in "path only" pattern:** NixOS options take secret _paths_, e.g.
  `users.users.<n>.hashedPasswordFile`, "read on each system activation" [nixos-users#L376-388].
  HM `programs.rclone.remotes.<n>.secrets` takes file paths and injects them at runtime
  [hm-rclone#L323-341]. Any tool, or a file you copy by hand, can feed these options.
- **Assessment:** only sops-nix and agenix are serious options for _this_ config.
  - vaultix has no darwin support.
  - clan wants to own the machine layout (inventory, `machines/<name>/`), which collides with
    `configurations.<class>.<host>` (ADR 0001).
  - opnix needs a 1Password account and a token file on disk, a secret you would still have to
    bootstrap. You have no 1Password [features#L470].
  - git-crypt puts the plaintext in the working tree, and Nix copies the flake source into the
    world-readable store.
  - agenix-rekey's generators and master key pay off with many hosts or a YubiKey. You have two
    hosts and no hardware key.

---

## 4. sops-nix vs agenix, on the points that matter here

### 4.1 darwin, system level

- **sops-nix:**
  - Runs `sops-install-secrets` in `postActivation` (via `mkAfter`) and as a launchd daemon with
    `RunAtLoad` [sops-darwin#L389-401].
  - Mounts a 64 MB `hdiutil` `ram://` disk as HFS (`nobrowse,nodev,nosuid`) at the mount point
    [sops-darwin-go#L29-65]. Secrets appear at `/run/secrets/<name>` [sops-darwin#L59-66].
  - Defaults: `owner = "root"`, `group = "staff"`, `mode = "0400"` [sops-darwin#L86-113].
  - `neededForUsers` "doesn't have any effect on macOS" [sops-darwin#L140-143].
  - Default identities: `/etc/ssh/ssh_host_ed25519_key` (and RSA for GPG), whether or not sshd
    runs [sops-darwin#L146-166] [sops-darwin#L303-309]. `age.keyFile` must not be a store path
    [sops-darwin#L20] [sops-darwin#L284-291].
  - The whole module is inert while `sops.secrets == {}` [sops-darwin#L357].
- **agenix:** runs only as a launchd daemon `activate-agenix` with `RunAtLoad`, under `set -e`
  [agenix-mod#L425-441]. It uses the same `hdiutil` RAM disk [agenix-mod#L35-43]. Default
  identities on darwin are `/etc/ssh/ssh_host_{ed25519,rsa}_key` [agenix-mod#L301-327].
- **Ordering on helios:** Home Manager also hooks `postActivation` [hm-darwin#L19-32]. sops-nix
  is `mkAfter`, so on a first switch the HM agents start before the secret exists. HM's rclone
  agent copes: it "retries on failure" until the provisioner's files appear [hm-rclone#L524-528].
- **helios fact:** `/etc/ssh/ssh_host_ed25519_key` exists, created 2026-10-26 16:04, while Remote
  Login (`com.openssh.sshd`) is not loaded [local]. Why it appeared then is unknown.
  **Assessment:** nix-darwin does not manage these keys, so don't use them as an identity. Set
  `sshKeyPaths = [ ]` and use an explicit `keyFile`.

### 4.2 darwin, Home Manager level

- **sops-nix HM:**
  - Uses a launchd agent with `RunAtLoad`, plus a `launchctl bootout`/`bootstrap` on every HM
    activation [sops-hm#L395-421].
  - Secrets go to `$(getconf DARWIN_USER_TEMP_DIR)/secrets.d` and are symlinked into
    `~/.config/sops-nix/secrets` [sops-hm#L184-200] [sops-readme#L783-787]. User mode still calls
    the RAM-disk mount [sops-main#L1387].
  - Tested on helios: as `ety` (uid 501), without sudo, `hdiutil attach -nomount ram://…`,
    `newfs_hfs` and `mount -t hfs -o nobrowse,nodev,nosuid,-m=0751` all succeed ("mounted by
    ety") [local]. So the user install really is in RAM.
  - `age.keyFile` defaults to `null` [sops-hm#L243-250]. The key "must have no password!"
    [sops-readme#L835].
  - Open darwin issues: activation fails with `Bootstrap failed: 5: Input/output error` from a
    bootout/bootstrap race [sops-997] [sops-910]. The agent can exit with `EX_CONFIG` at boot
    [sops-801].
- **agenix HM:**
  - On darwin there is no mount step at all: generations go straight into
    `$(getconf DARWIN_USER_TEMP_DIR)/agenix.d` on disk [agenix-hm#L23-32]
    [agenix-ref#L323-332].
  - Its agent sets `KeepAlive = { Crashed = false; SuccessfulExit = false; }`
    [agenix-hm#L275-289]. `man launchd.plist` on helios says `Crashed` false means "the job will
    be restarted" unless it crashed [local]. So it restarts after every clean exit, as reported
    in the open [agenix-372].
  - Default identities are `~/.ssh/id_ed25519` and `~/.ssh/id_rsa` [agenix-ref#L314-321].
- **Assessment:** on darwin, the HM level is the weak spot of both tools. With one User, the
  system module and `owner = "ety"` give the same result without any `launchctl` dance. HM
  modules then read `osConfig.sops.secrets.<n>.path`, the way `_backup-home.nix` already reads
  `osConfig` [backup-home].

### 4.3 NixOS (typhon, short)

- sops-nix: `neededForUsers = true` decrypts to `/run/secrets-for-users` before users are created,
  which is what `hashedPasswordFile` needs [sops-readme#L572-600]. Known gap: initrd secrets
  [sops-readme#L997-1006] (not needed: LUKS is typed at boot).
- agenix: orders `users.deps = [ "agenixInstall" ]`, or uses systemd units under sysusers
  [agenix-mod#L340-420]. It mounts tmpfs with `noswap` on kernel 6.4 and later, otherwise ramfs
  [agenix-mod#L44-61].

### 4.4 Failure modes during activation

- **sops-nix:** decrypts _all_ secrets first, then renders templates, writes a new generation
  directory and swaps one symlink atomically. Any error returns before the swap
  [sops-main#L1447-1485]. Missing keys in a file are caught at build time:
  "sops files are checked against the configuration at evaluation time" [sops-readme#L30].
- **agenix:** decrypts secret by secret into a new generation, then links it and deletes the
  previous generation [agenix-mod#L98-149]. On darwin the daemon runs under `set -e`
  [agenix-mod#L427-429]. In the NixOS activation-script path there is no early exit in the
  snippet. **Unverified (read, not tested):** a failed decrypt there would still link a
  generation without that secret.
- **Assessment:** the most likely failure on helios is "key file missing". With sops-nix,
  `darwin-rebuild` then reports an error at the very end and the old secrets stay. Create the key
  before the first switch (§9).

### 4.5 Editing, adding a Host, templates

- **sops:**
  - `.sops.yaml` creation rules match the path relative to `.sops.yaml`, first match wins
    [sops-config#L576-598].
  - `sops edit FILE`, `sops set --value-stdin`, `sops updatekeys` (after changing recipients) and
    `sops rotate` (new data key) are all subcommands in 3.13.3 [local]
    [sops-readme#L420-423].
  - A "key_groups" entry must not repeat `-` before each key type, or sops starts requiring
    several keys (Shamir) [sops-readme#L234-238].
  - Templates use `config.sops.placeholder.<n>` inside `sops.templates.<f>.content`
    [sops-readme#L1018-1070]. A placeholder used _outside_ a template stays a literal string, as
    in the open [sops-804].
- **agenix:** you edit with `agenix -e`. After changing keys you run `agenix --rekey`, which needs
  a key that can decrypt and rewrites every file [agenix-rekeying]. `agenix --check` compares
  recipients without decrypting [agenix-ref#L367-374]. There are no templates.

### 4.6 Keys: post-quantum, plugins, SSH

- **age 1.3.0** added hybrid ML-KEM-768 + X25519 recipients (`age1pq1…`, `age-keygen -pq`), and
  `age1tag1…` recipients for hardware plugins [age-1.3.0]. age refuses to mix PQ and classic
  recipients in one file ("the file would be vulnerable to quantum computers") [age-go#L88-100]
  [age-go#L211-217].
- **sops 3.10** added SSH recipients and identities plus age plugins. **sops 3.12** added PQ
  identities [sops-changelog#L208-217] [sops-changelog#L465-515]. sops reads, in order:
  `SOPS_AGE_SSH_PRIVATE_KEY_FILE`/`_CMD`, `~/.ssh/id_ed25519`, `~/.ssh/id_rsa`, `SOPS_AGE_KEY`,
  `SOPS_AGE_KEY_FILE`, `SOPS_AGE_KEY_CMD`, then `<UserConfigDir>/sops/age/keys.txt`
  [sops-age#L319-470]. On macOS that last path is `~/Library/Application Support/…` unless
  `XDG_CONFIG_HOME` is set [sops-age#L46-50] [sops-age#L393-399]. It is unset on helios [local].
- **Tested on helios** with sops 3.13.3 and age 1.3.2 from the lock [local]:
  - `sops encrypt`/`decrypt` work with a PQ key.
  - The key name `nas-pass:` stays readable in the encrypted file.
  - A PQ recipient is 1959 characters long; its identity is 77.
  - `age -r <pq> -r <classic>` is refused.
  - `sops encrypt --age <pq>,<classic>` is **accepted**, because sops wraps the data key once per
    recipient [sops-age#L163-199].
- **Assessment:** in sops, a file is only as quantum-safe as its weakest recipient. Keep _every_
  recipient in `.sops.yaml` an `age1pq1…` key. That rules out `ssh-to-age`, sops-nix's
  `generateKey` (it calls plain `age-keygen` [sops-darwin#L168-183]) and YubiKey PIV keys.
- **Secure Enclave** (`age-plugin-se`): nixpkgs has 0.1.4 [lock]. PQ and `tag` recipients arrived
  in 0.2.0 [se-releases]. Keys are created with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
  [se-plugin#L30-49], so they only work while the Mac is unlocked. That rules out a boot-time root
  daemon. On darwin, `sops.age.plugins` also overwrites the daemon's PATH and loses `hdiutil`
  [sops-darwin#L405-407] [sops-957]. **Assessment:** a later upgrade for the _editing_ key only,
  once nixpkgs ships 0.2.

---

## 5. Threat model for a public repo

- **Ciphertext is public forever** (forks, clones, archives). A recipient key that leaks later
  decrypts every old commit encrypted to it [rekey-readme#L833-835]. Rekeying alone does not
  undo that. After a key leak: change the secret _values_, then `sops updatekeys` and
  `sops rotate`.
- **Future quantum attacks:** age said in 2024 that it was not PQ-safe; agenix's own warning
  still says so [agenix-threat#L16-21]. Since 1.3.0, PQ is available [age-1.3.0].
  **Assessment:** `-pq` costs nothing at bootstrap. Use it.
- **Metadata that leaks:**
  - sops: YAML key names, every recipient public key, `lastmodified` and the sops version are in
    plaintext. Comments are encrypted [sops-readme#L383-418] [local].
  - agenix: file names, the rules file, and a 32-bit tag per SSH recipient
    [agenix-ref#L367-374].
  - **Assessment:** use neutral names (`nas-pass`, not the NAS address). Put the NAS host and
    user in the secret too (HM rclone `secrets` takes any field [hm-rclone#L323-341]).
- **Integrity:** anyone with the public keys can write a new, valid secret file. sops adds a MAC
  over the values; plain age does not [agenix-threat#L5-14]. **Assessment:** the real boundary
  is push access to the repo, which already controls the whole config.
- **Nix store:** encrypted files are copied into the store, which is fine
  [sops-readme#L433-436]. Never `builtins.readFile` a decrypted path, or the cleartext lands in
  the world-readable store [agenix-ref#L86-96].
- **On helios at runtime:** secrets sit in RAM, owned by `ety` with mode 0400. The key file is
  readable by anything running as `ety`, including AI agents and npm install scripts.
  **Assessment:** this matches `rclone.conf` today, so nothing gets worse. rclone's `pass` is
  only "obscured", which is **not** "a secure way of encrypting these passwords" [rclone-obscure].
  Optionally, deny agents read access to `~/Library/Application Support/sops/`.

---

## 6. Alternatives considered for helios only

- **macOS Keychain + `security find-generic-password`** (for example rclone's
  `--password-command`).
  - Pros: no new flake input, the key lives in the keychain, and iCloud Keychain is end-to-end
    encrypted [apple-adp].
  - Cons: it is not declarative, typhon cannot use it, and a fresh Mac means retyping every value.
  - **Assessment:** right for interactive, per-device credentials (§8), wrong for config secrets
    shared across Hosts.
- **Separate private secrets repo as a flake input.**
  - Pros: no public ciphertext and no metadata leak.
  - Cons: fetching it needs a GitHub token, itself a secret on every Host; public CI can no longer
    evaluate; and you have two repos to keep in step.
  - **Assessment:** use it only if secret _names_ themselves become sensitive.

---

## 7. Keys, loss and backup

- **Key layout:**

  | Key                          | Where                                                   | Who reads it                                                                               | Backed up?                                                        |
  | ---------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------- |
  | `helios` (`age1pq1…`)        | `~/Library/Application Support/sops/age/keys.txt`, 0600 | `sops` CLI (default path [sops-age#L393-399]) and the root activation (`sops.age.keyFile`) | No: per device                                                    |
  | `recovery` (`age1pq1…`)      | Apple Passwords only (77 characters)                    | you, during recovery, via `SOPS_AGE_KEY` [sops-age#L29] [sops-age#L413-419]                | Yes: iCloud Keychain, end-to-end encrypted by default [apple-adp] |
  | `typhon` (`age1pq1…`, later) | `/var/lib/sops-nix/key.txt`, root 0600                  | root activation                                                                            | No: per device                                                    |

- **Why one key on helios:** every helios secret is owned by `ety`. A separate root-only key
  would protect nothing, since `ety` can read `/run/secrets/*` anyway. **Assessment, not
  verified:** with FileVault on Apple Silicon the volume is unlocked before launchd daemons start,
  so the boot-time daemon can read a file under `~`.
- **backup-home:** `- /Library/**` already excludes the helios key [backup-home#L54]. Keep it that
  way, for the same reason SSH keys are excluded: "SSH keys are per device"
  [backup-home#L56-59]. The NAS is a plain mirror, so a key stored there would let anyone with
  NAS access read every secret.
- **If helios is lost:** on the new Mac, follow rebuild-from-zero. Create a new helios key, swap
  its recipient into `.sops.yaml`, run
  `SOPS_AGE_KEY="$(pbpaste)" sops updatekeys secrets/*.yaml` with the recovery key on the
  clipboard, commit, then switch. The NAS password comes back from git, and the backups with it.
- **If the recovery key is lost but helios still works:** make a new one and run `updatekeys`.
  **If both are lost:** the secrets are gone. Every one of them can be reset (NAS, user password,
  restic repo password only by re-initialising). That is the real cost of a lost key.

---

## 8. What should NOT go in sops (concretely)

- **gh token:** already in the keychain ("Logged in … (keyring)") [local]. gh falls back to a
  plain file only without a credential store [gh-help]. Keep `hosts.yml` unmanaged (gh.nix).
- **SSH private key `~/.ssh/id_ed25519`:** per device, never copied [backup-home#L56-59]. Only
  the public half lives in `users/ety.nix`.
- **SSH key passphrase:** Apple's ssh with `UseKeychain` [features#L465-469]. A passphrase also
  makes the key unusable as a non-interactive sops/agenix identity [sops-readme#L835]
  [sops-age#L578-583]. One more reason not to derive the age key from it.
- **typhon LUKS passphrase:** typed at boot, and handed to nixos-anywhere as a temp file
  [adr-0002#L13].
- **Tailscale:** the helios app keeps its own state. On typhon, a one-time `sudo tailscale up` is
  simpler than an expiring auth key in the repo (assessment).
- **macOS Wi-Fi, FileVault recovery key, app logins** (Discord, Teams, eM Client, NordVPN,
  Firefox Sync): owned by macOS or the app.
- **Project `.envrc` tokens:** they belong to their projects, not this config. Per-project
  `sops exec-env` is possible but out of scope.
- **Goes in sops:** NAS credentials (optional now), typhon `ety` hash, restic password and repo
  credentials, Syncthing cert/key (only for a stable device ID), and typhon Wi-Fi PSK if needed.

---

## 9. Where it goes in the dendritic layout

Repo-root files (outside `modules/`, so import-tree ignores them):

```yaml
# .sops.yaml — every recipient must be age1pq1…, or the file loses PQ protection
keys:
  - &helios age1pq1… # ~/Library/Application Support/sops/age/keys.txt on helios
  - &recovery age1pq1… # private half only in Apple Passwords
  # - &typhon age1pq1…   # /var/lib/sops-nix/key.txt, added at typhon's install
creation_rules:
  - path_regex: ^secrets/helios\.yaml$
    key_groups:
      - age: [*helios, *recovery]
  # - path_regex: ^secrets/typhon\.yaml$
  #   key_groups:
  #     - age: [*helios, *recovery, *typhon]
```

`flake.nix` input (sops-nix's own nixpkgs is only used by its own outputs; the modules build from
your `pkgs` [sops-darwin#L258-265]):

```nix
sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

`modules/features/secrets.nix`. The module is imported once, through each Class's `base`. That is
safe because it is inert while no secret is declared [sops-darwin#L357]:

```nix
# sops-nix, system level only: decrypts secrets/<host>.yaml at activation
# into /run/secrets (a RAM disk on darwin). HM modules read paths via
# osConfig. Keys and recovery: docs/adr/0005.
{ inputs, ... }:
{
  flake.modules.darwin.base = {
    imports = [ inputs.sops-nix.darwinModules.sops ];
    # Native PQ age keys only; never the macOS host key.
    sops.age.sshKeyPaths = [ ];
    sops.gnupg.sshKeyPaths = [ ];
  };

  flake.modules.nixos.base = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";
    sops.age.sshKeyPaths = [ ];
    sops.gnupg.sshKeyPaths = [ ];
  };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.sops pkgs.age ];
    };
}
```

Host module, `modules/hosts/helios/default.nix` (a Host setting, allowed in
`configurations.darwin.helios.module`):

```nix
sops.defaultSopsFile = ../../../secrets/helios.yaml;
```

User side, `modules/users/ety.nix` → `flake.modules.darwin.ety` (the key belongs to the User):

```nix
sops.age.keyFile = "/Users/ety/Library/Application Support/sops/age/keys.txt";
sops.secrets = {
  nas-host.owner = "ety";
  nas-user.owner = "ety";
  nas-pass.owner = "ety";
};
```

Consumer, `modules/users/_backup-home.nix` (already an HM module with `osConfig`):

```nix
programs.rclone = {
  enable = true;
  remotes.i14-nas = {
    config.type = "<same type as today's rclone.conf>";
    secrets = {
      host = osConfig.sops.secrets.nas-host.path;
      user = osConfig.sops.secrets.nas-user.path;
      pass = osConfig.sops.secrets.nas-pass.path;
    };
  };
};
```

- HM runs `rclone config update … <field>="$(cat file)"` and so writes the obscured form, as
  today [hm-rclone#L545-552]. It manages `~/.config/rclone/rclone.conf` through a launchd agent
  that retries [hm-rclone#L618-634].
- Gotchas: back up the current `rclone.conf` before the first switch. `programs.rclone` adds
  `rclone` to `home.packages`, so drop it from `users/ety.nix`. Update the header comment of
  `_backup-home.nix`.

---

## 10. Review of best-of-nix §4.2 and §8 step 13

- **Still correct:**
  - sops formats, age/GPG and `ssh-to-age` [sops-readme#L36-46].
  - NixOS, darwin and HM modules [sops-flake#L63-82].
  - The HM launchd agent on darwin [sops-hm#L395-406].
  - The CLI key path `~/Library/Application Support/sops/age/keys.txt` [sops-readme#L180].
  - agenix 0.18.0, and darwin/HM modules [agenix-flake#L33-40].
  - ragenix's last tag `2025.03.09`.
- **Incomplete or outdated:**
  1. "The user age key goes in `~/Library/Application Support/…`" is true for the `sops` CLI only
     (and only without `XDG_CONFIG_HOME`). Neither sops-nix module reads it unless you set
     `sops.age.keyFile`, which defaults to `null` [sops-hm#L243-250] [sops-darwin#L284-291].
  2. "agenix uses … plain SSH recipients" is outdated. It takes any age recipient, and its rules
     file is now `agenix-rules.nix`, with `secrets.nix` deprecated [agenix-ref#L361-380].
  3. Its agenix-rekey note cited only the best-of-nix list. Upstream it also has generators and
     HM modules [rekey-readme#L1-33] [rekey-flake#L60-72].
  4. "import `homeManagerModules.sops` into `homeManager.base`" is not needed. On darwin it is the
     part with open activation bugs [sops-997] [sops-910] [sops-801]. Use the system modules with
     `owner`.
  5. The pick's reasoning ("because you used it before, … more stars") is replaced by §1. "Either
     is fine" undersells real darwin differences (RAM vs disk at HM level, atomic install,
     agenix's HM restart loop [agenix-372]).
  6. §8 step 13, "an age key derived from your SSH key", is **overturned**. Classic keys are not
     PQ, the public repo makes that matter, and a future SSH passphrase would break decryption
     (§4.6, §8).

---

## 11. Bootstrap on helios (exact commands)

Run from `~/nix-config`. The tools come from the locked nixpkgs, so the versions match the
tests above.

```bash
cd ~/nix-config
nix shell --inputs-from . nixpkgs-darwin#age nixpkgs-darwin#sops

# 1. helios key (age-keygen writes it with mode 0600 and never overwrites)
mkdir -p ~/Library/Application\ Support/sops/age
age-keygen -pq -o ~/Library/Application\ Support/sops/age/keys.txt
age-keygen -y ~/Library/Application\ Support/sops/age/keys.txt   # → &helios in .sops.yaml

# 2. recovery key: generate in a private temp dir, store, verify, delete
d=$(mktemp -d); age-keygen -pq -o "$d/r.txt"
age-keygen -y "$d/r.txt"                       # → &recovery in .sops.yaml
grep '^AGE-SECRET-KEY-PQ-1' "$d/r.txt" | pbcopy
#    Paste it into Apple Passwords as a new entry "nix-config sops recovery".
#    Then copy it back from Passwords and check it is the same key:
pbpaste | age-keygen -y | diff - <(age-keygen -y "$d/r.txt") && echo "recovery key OK"
rm -r "$d"; pbcopy </dev/null

# 3. write .sops.yaml (§9), then create the secrets file
EDITOR="code --wait" sops edit secrets/helios.yaml     # nas-host / nas-user / nas-pass

# 4. prove the recovery key alone can decrypt (copy it from Passwords first)
SOPS_AGE_KEY="$(pbpaste)" sops decrypt secrets/helios.yaml >/dev/null && echo "recovery decrypts"
pbcopy </dev/null

# 5. wire it in (§9), make the files visible to the flake, build, switch
git add .sops.yaml secrets/helios.yaml modules/features/secrets.nix
nh darwin build && nh darwin switch

# 6. check
ls -l /run/secrets/                          # nas-* owned by ety, -r--------
mount | grep secrets.d                       # hfs RAM disk, nobrowse
sudo launchctl print system/org.nixos.sops-install-secrets | grep 'last exit code'
rclone lsf i14-nas:home/backup --max-depth 1
```

- `sops edit` decrypts into a temporary file while your editor is open. That is normal, and
  FileVault is on.
- Adding a value later without opening an editor:
  `printf %s "$v" | sops set --value-stdin secrets/helios.yaml '["name"]'`.
- **typhon later (short):**
  1. On helios: `age-keygen -pq -o "$t/var/lib/sops-nix/key.txt"`, then add its recipient, run
     `sops updatekeys secrets/typhon.yaml`, and pass `--extra-files "$t"` to nixos-anywhere
     [nxa-secrets#L10-39].
  2. Declare `sops.secrets.ety-password.neededForUsers = true;` and
     `users.users.ety.hashedPasswordFile = config.sops.secrets.ety-password.path;`
     [sops-readme#L572-600].
  3. Delete `$t` afterwards.

**ADR:** write `docs/adr/0005-secrets.md`. It should record sops-nix at system level, PQ-only
recipients, the three keys, keeping keys out of backup-home, and the recovery procedure. Each of
these is expensive to reverse.

---

## 12. Limitations (not verified)

- No real `nh darwin switch` with sops-nix was run (the config was not changed). The RAM-disk
  mount, PQ encryption and decryption, and the refusal to mix keys were tested directly [local].
- How long `sops-install-secrets` takes to build the first time (it is a Go build from your
  `pkgs`, not in cache.nixos.org as such).
- Whether macOS wipes `DARWIN_USER_TEMP_DIR` at reboot. This decides how long agenix-HM secrets
  stay on disk.
- Whether the boot-time root daemon can always read `~/Library/Application Support` (FileVault,
  TCC). Fallback: put the key in `/var/lib/sops-nix/key.txt` and edit with `SOPS_AGE_KEY_FILE`.
- Why helios's SSH host keys were created on 2026-10-26.
- agenix's NixOS behaviour after a failed decrypt (read from the code, not run).
- That `age-plugin-se` 0.2's PQ keys work through sops-nix.

---

## 13. Sources

Metadata and local

- [gh-meta] `gh api repos/<o>/<r>`, `…/releases/latest`, `…/tags` on 2026-10-28; `gh api
repos/Ety0011/nix-config` → `"visibility":"public"`.
- [lock] `nix eval --inputs-from . nixpkgs-darwin#<pkg>.version` at `nixpkgs-26.05-darwin` @
  `d592aacecd35`: age 1.3.2, sops 3.13.3, ssh-to-age 1.2.0, age-plugin-se 0.1.4,
  age-plugin-yubikey 0.5.1, ragenix 2025.03.09, git-crypt 0.8.0; `agenix` not found.
- [local] helios, 2026-10-28, macOS 26.6.2: `ls -l /etc/ssh`, `stat` of the host keys,
  `launchctl print system/com.openssh.sshd` (not found), `gh auth status`, key names in
  `rclone.conf` (values not read), `XDG_CONFIG_HOME` unset, `man launchd.plist` (`Crashed`,
  `SuccessfulExit`), the RAM-disk mount as uid 501, the sops/age PQ tests with throwaway keys
  (deleted), and `sops --help`.
- This repo @ `61ae255`: [backup-home] `modules/users/_backup-home.nix` (L1-3, L54, L56-59),
  [gh.nix] `modules/features/gh.nix`, [features] `docs/research/features.md` (L23-24, L60-61,
  L67, L71, L413-422, L443-444, L461-470), [adr-0002] `docs/adr/0002-typhon-disk-layout.md`
  (L13).

sops-nix @ `60182817ee048ac94b4c68ea76d5ef2e8aac730d`

- [sops-readme] https://github.com/Mic92/sops-nix/blob/60182817ee048ac94b4c68ea76d5ef2e8aac730d/README.md
  (L7-30, L36-46, L180, L216-238, L383-423, L428-462, L572-600, L780-856, L995-1016, L1018-1070)
- [sops-flake] …/flake.nix (L3, L63-82) · [sops-gomod] …/go.mod (L8)
- [sops-darwin] …/modules/nix-darwin/default.nix (L20, L59-66, L86-113, L140-143, L146-183,
  L258-265, L284-319, L357, L389-407)
- [sops-hm] …/modules/home-manager/sops.nix (L184-200, L243-276, L322, L395-421)
- [sops-darwin-go] …/pkgs/sops-install-secrets/darwin.go (L13-21, L29-93)
- [sops-main] …/pkgs/sops-install-secrets/main.go (L1337-1357, L1387, L1447-1485)
- [sops-pkg] …/pkgs/sops-install-secrets/default.nix (L3-38)
- Issues: [sops-997] https://github.com/Mic92/sops-nix/issues/997 · [sops-910] …/issues/910 ·
  [sops-801] …/issues/801 · [sops-804] …/issues/804 · [sops-957] …/issues/957

sops v3.13.3 @ `26e2f4784ca61353082c32dbd987c25eda086dc9`

- [sops-age] https://github.com/getsops/sops/blob/26e2f4784ca61353082c32dbd987c25eda086dc9/age/keysource.go
  (L29-50, L163-199, L319-470, L489-520, L562-583)
- [sops-config] …/config/config.go (L570-598) · [sops-changelog] …/CHANGELOG.md (L208-217,
  L465-515)

age v1.3.2 @ `b74dce4cdbe35b5e5f66c06d9612b72f89028758`

- [age-go] https://github.com/FiloSottile/age/blob/b74dce4cdbe35b5e5f66c06d9612b72f89028758/age.go
  (L88-100, L211-217)
- [age-1.3.0] https://github.com/FiloSottile/age/releases/tag/v1.3.0

agenix @ `5e5b88a0c8e56f291a108c2fe9934054d9745b2e`

- [agenix-readme] https://github.com/ryantm/agenix/blob/5e5b88a0c8e56f291a108c2fe9934054d9745b2e/README.md
- [agenix-flake] …/flake.nix (L4-6, L33-40)
- [agenix-mod] …/modules/age.nix (L20, L35-61, L98-149, L301-327, L340-420, L425-441)
- [agenix-hm] …/modules/age-home.nix (L23-32, L46-82, L275-289)
- [agenix-ref] …/doc/reference.md (L86-96, L314-332, L334-380) · [agenix-rekeying]
  …/doc/rekeying.md (L1-13) · [agenix-threat] …/doc/threat-model-warnings.md (L1-21)
- [agenix-372] https://github.com/ryantm/agenix/issues/372

Others

- [rekey-readme] https://github.com/oddlama/agenix-rekey/blob/87e5d5f2ca5de294eb5386c2773b94d58ec9773b/README.md
  (L1-33, L803-835) · [rekey-flake] …/flake.nix (L2-21, L60-72)
- [ragenix-flake] https://github.com/yaxitech/ragenix/blob/83bccfdea758241999f32869fb6b36f7ac72f1ac/flake.nix
  (L5-14, L366-367)
- [clan-vars-intro] https://github.com/clan-lol/clan-core/blob/dbae21013aca57424620d06863cbfd2e4107352b/docs/src/guides/vars/intro-to-vars.md ·
  [clan-vars-age] …/docs/src/guides/vars/age/age-backend.md · [clan-macos] …/docs/src/guides/macos.md
- [opnix-readme] https://github.com/brizzbuzz/opnix/blob/0ea3a9e6a94fdd0c444aa7729b98e568a0588222/README.md (L56-60)
- [vaultix-readme] https://github.com/milieuim/vaultix/blob/8e6331194139366a0398d936b68ff9926ecf3221/README.md
- [se-plugin] https://github.com/remko/age-plugin-se/blob/57ccea12fc1a3d3bb81b8866745be4d2951c4eaf/Sources/Plugin.swift
  (L30-49) · [se-readme] …/README.md (L116-119, L159-178, L218-226, L260-302) · [se-releases]
  https://github.com/remko/age-plugin-se/releases (v0.2.0, 2025-12-27)
- [hm-rclone] home-manager `release-26.05` @ `24f2190587513b9c2f73db112a17844ae912d965`,
  https://github.com/nix-community/home-manager/blob/24f2190587513b9c2f73db112a17844ae912d965/modules/programs/rclone.nix
  (L11, L323-341, L495-529, L545-552, L618-634) · [hm-darwin] …/nix-darwin/default.nix (L19-32)
- [nixos-users] nixpkgs `nixos-26.05` @ `1f607aa79b6356ed45d3cd3c8079c196e79efa2c`,
  …/nixos/modules/config/users-groups.nix (L376-388)
- [nxa-secrets] https://github.com/nix-community/nixos-anywhere/blob/92b94751fc010eab62d07de40972cffa6937cafd/docs/howtos/secrets.md (L10-39)
- [gh-help] `gh auth login --help`, gh 2.103.2 (L6-10, L55)
- [rclone-obscure] https://rclone.org/commands/rclone_obscure/ (fetched 2026-10-28)
- [apple-adp] https://support.apple.com/en-us/102651 ("Passwords and Keychain": end-to-end under
  Standard Data Protection; fetched 2026-10-28)
