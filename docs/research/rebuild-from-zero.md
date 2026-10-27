# Rebuild from zero: blank machine to `helios` and `typhon`

Research date: 2026-10-27. Scope: the exact steps from a blank Mac to the `helios` Host and from a
blank PC to the `typhon` Host, written so they can become a README checklist. Restoring personal
data (Time Machine, `~/Documents`, app settings) is out of scope.

Locked inputs read (from `flake.lock`, read from their `/nix/store` copies): nix-darwin
`nix-darwin-26.05` @ `d31953cf55f9`, home-manager `release-26.05` @ `24f219058751`, nixpkgs
`nixos-26.05` @ `1f607aa79b63`, nixpkgs `nixpkgs-26.05-darwin` @ `d592aacecd35`, disko @
`cedd626e11b6`. Tools that are not inputs were read at their current heads: nixos-anywhere `main`
@ `92b94751fc01` (same commit as `best-of-nix.md`), nixos-facter `main` @ `301b533c0542`, the Nix
install script as served by nixos.org today (Nix 2.35.4), Homebrew `install` @ `85d1a3fc80d8`.
State on helios was inspected read-only [local]. "Fact" statements carry a citation;
**Assessment** marks my judgement.

---

## 1. TL;DR

- **helios, in order:** create the macOS admin account with the short name `ety` → install
  upstream Nix with the official script (`curl … https://nixos.org/nix/install | sh`) → install
  Homebrew with its official script (this also installs the Xcode Command Line Tools, and so
  `git`) → `git clone --branch develop https://github.com/Ety0011/nix-config.git ~/nix-config` →
  `sudo nix --extra-experimental-features 'nix-command flakes' run
nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake "$HOME/nix-config#helios"` → new
  terminal → SSH key, `gh auth login`, macOS privacy grants. After that, `nh darwin switch`.
- **helios was set up the same way** on 2026-02-10. It used the official script (Nix 2.33.2), so a
  rebuild following this list matches what helios has [local].
- **On macOS 26 you do not rename any `/etc` files by hand.** nix-darwin 26.05 knows the hashes
  of the stock macOS files and of what the official installer writes, and renames them to
  `*.before-nix-darwin` itself [nd-etc#L66-77,L112] [nd-zsh] [nd-bash] [nd-nixconf]. You only
  rename by hand if activation stops with "Unexpected files in /etc".
- **Keeping `system.stateVersion = 6` and `home.stateVersion = "24.11"` on a new Mac that
  replaces helios is correct.** The HM manual says to keep the release "you first used for this
  home configuration" [hm-upgrading#L147-166]. In nix-darwin, 6 and 7 differ only in tmux
  bindings, which this config does not use [nd-version#L54] [nd-tmux#L62].
- **typhon:** the steps in `modules/hosts/typhon/default.nix` are right in outline, but five
  things are missing or wrong (§4). The main ones: how to boot an installer you can SSH into
  (`sudo passwd` on the NixOS ISO), `ssh -t` for `passwd ety`, and wiring
  `hardware.facter.reportPath` into `_hardware.nix` _before_ the install, alongside the boot
  loader, not in place of it.

---

## 2. helios (aarch64-darwin)

### 2.1 Which Nix installer

- **Official script.** nixos.org/download gives the macOS command as
  `curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh` and requires macOS 14
  or newer [nixos-download]. Today the script fetches Nix 2.35.4 [nix-install-sh#L84]. On Darwin
  it always does a multi-user (daemon) install: `INSTALL_MODE=daemon` is the default, and
  `--no-daemon` is refused on macOS [nix-tarball#L49-54,L61-70]. **You do not need `--daemon`.**
  Its flags are `--daemon`, `--no-daemon`, `--yes`, `--no-channel-add`, `--no-modify-profile`,
  `--daemon-user-count` and `--nix-extra-conf-file` [nix-tarball#L94]. It does **not** enable
  flakes: the `/etc/nix/nix.conf` it writes contains only `build-users-group = nixbld`
  [nix-multi#L998-1004], and `flakes` and `nix-command` are still experimental features in Nix
  2.35.4 [nix-xp#L77-80,L100-103].
- **NixOS/nix-installer** (the Rust installer) is "the official Nix installer maintained by the
  NixOS community", still "Status: Beta". It has an `--enable-flakes` flag and keeps
  `/nix/receipt.json` for uninstalling [nixos-installer#L3-31,L348].
- **The Determinate installer** can still install upstream Nix with `--prefer-upstream-nix`, but
  its README calls that "not a supported configuration" [detsys#L15,L389,L435-452]. If it
  installs Determinate Nix instead, nix-darwin aborts activation ("Determinate detected") unless
  you set `nix.enable = false` [nd-checks#L47-60]. That would hand over `nix-daemon.nix`, which
  `best-of-nix.md` already rejected.
- **Does the choice matter?** Less than it seems. The nix-darwin README says "the installer you
  use doesn't affect which Nix interpreter your system will use later on", because nix-darwin
  manages Nix and defaults to upstream [nd-readme#L14-18]. (The README actually recommends the
  Lix _installer_, for its uninstaller [nd-readme#L16].)
- **Assessment:** use the official script. It matches helios. Its `/etc` files have hashes that
  nix-darwin 26.05 has known for years, so the first switch renames them automatically. The Rust
  installer's `nix.custom.conf` is only known for Nix 2.33.3 [nd-nix#L889-937]. With a newer
  installer version, the first switch may abort with "custom settings in
  `/etc/nix/nix.custom.conf`".
- **What helios has** [local]:
  - No `/nix/receipt.json`, so it was not installed by a Rust installer.
  - It has `/etc/{bashrc,zshrc}.backup-before-nix`, the official script's backup suffix
    [nix-multi#L38].
  - It has the official script's encrypted-volume daemon `org.nixos.darwin-store.plist`. FileVault
    is on, and with FileVault on the script encrypts the Nix volume by default [nix-volume#L75-84].
  - The `nixbld` group has GID 350 and `_nixbld1` has UID 351, the script's defaults
    [nix-darwin-multi#L16-17].
  - The root profile holds `nix-2.33.2`. All of these files date from 2026-02-10.
  - The running daemon is nixpkgs' `nix-2.34.9+1`, installed by nix-darwin.
  - `/etc/nix/nix.conf.before-nix-darwin` is the 28-byte installer file. Its hash `ff08c1…` is the
    one nix-darwin labels "official Nix installer as of 2.4" [nd-nix#L749].
  - zsh history shows the first switch was
    `sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin/nix-darwin-25.05#darwin-rebuild -- switch`.

### 2.2 Prerequisites that are not in the config

- **The macOS user `ety` must already exist and be an admin.** nix-darwin does not create it:
  `users.knownUsers` lists the users nix-darwin may create or delete, and the docs say "Don't add
  the admin user" [nd-users#L61-68]. `users/ety.nix` does not list it. Activation checks that
  `system.primaryUser` exists and aborts if not [nd-checks#L34-44]. **Assessment:** in Setup
  Assistant, set the _account name_ to `ety`. Typing "Etienne" as the full name proposes
  `etienne`, and the home must be `/Users/ety` (`users/ety.nix`).
- **Admin rights:** the config trusts `@admin` (`nix-daemon.nix`). On helios, `admin` contains
  `ety` [local].
- **macOS version:** Homebrew needs macOS 15 or newer on Apple Silicon [brew-installation#L36-42].
  The Nix script needs 14 or newer [nix-tarball#L30-42].
- **Xcode Command Line Tools:** Nix and nix-darwin do not need them. The Homebrew script installs
  them when `/Library/Developer/CommandLineTools/usr/bin/git` is missing
  [brew-install#L446-452,L783,L888-920], and that gives you `git`.
- **Rosetta: not needed.** Every declared cask and brew has an arm64 build. `vorssaint` even
  declares arm64 only [local: `brew info --json=v2`, `lipo -archs`].
- **Mac App Store sign-in: not needed.** `homebrew.masApps` is not set anywhere in the config.
  That sign-in matters only for `masApps` [nd-brew#L857-871].

### 2.3 Getting the repo onto the Mac

- The repo is public, and its remote is HTTPS [local]. So cloning needs no SSH key and no `gh`
  login.
- **It must be at `~/nix-config`.** `programs.nh.flake = "${home}/nix-config"` exports `NH_FLAKE`
  [hm-nh#L109-115].
- **Which branch:** helios runs `85884a8`, which is `develop`. `main` (the default branch) is 10
  commits behind [local: `darwin-version --configuration-revision`]. Clone `develop`, or merge it
  into `main` first.
- **Options:**
  1. **After the Homebrew step:** `git clone --branch develop https://github.com/Ety0011/nix-config.git ~/nix-config`.
     This uses the CLT `git`. **Assessment:** this is the simplest.
  2. Without the CLT:
     `nix --extra-experimental-features 'nix-command flakes' run nixpkgs#git -- clone …`.
  3. `nix flake clone` "performs a Git … clone" [local: `nix flake clone --help`]. It needs a `git`
     binary anyway, so it saves nothing.

### 2.4 Homebrew

- **nix-darwin does not install Homebrew:** "enabling this option does not install Homebrew, see
  the Homebrew website" [nd-brew#L653-659]. The official command is
  `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
  [brew-installation#L138].
- **If Homebrew is missing at switch time:** activation prints "Homebrew is not installed,
  skipping..." and continues [nd-brew#L1022-1035]. But `homebrew.enableZshIntegration` puts an
  unguarded `eval "$(/opt/homebrew/bin/brew shellenv zsh)"` into `/etc/zshrc`
  [nd-brew#L980-982], so every new shell would print an error. **Install Homebrew before the
  first switch.**
- **Ignore the installer's "Next steps"** (appending `brew shellenv` to `~/.zprofile`)
  [brew-install#L1137-1154]. The zsh integration already does it. helios still has that stale
  `~/.zprofile` from the first install (`features.md` §2).
- **The cleanup mode is harmless on a blank Mac.** `cleanup = "uninstall"` only removes formulae
  and casks that are installed but not declared.
- **The first switch installs 14 casks and 3 brews as `ety`** [nd-brew#L681-683]. The `.pkg`
  casks (eM Client, Teams, NordVPN, Tailscale) call `sudo`, which by default authenticates that
  account [brew-installation#L98-101]. **Assessment:** expect password or Touch ID prompts during
  activation.

### 2.5 `/etc` files nix-darwin will not overwrite blindly

- **How the check works:** for every `/etc` file nix-darwin manages, activation compares the
  existing file's SHA-256 with a list of known hashes. If it matches, the file is moved to
  `<file>.before-nix-darwin` automatically [nd-etc#L66-77,L112]. Otherwise activation stops with:
  "error: Unexpected files in /etc, aborting activation … Please check there is nothing critical
  in these files, rename them by adding .before-nix-darwin to the end, and then try again"
  [nd-etc#L80-90].
- **Files this config manages, and the sources they have known hashes for:**
  - `/etc/nix/nix.conf`: official installer (several versions), Determinate, Lix [nd-nix#L743-761].
  - `/etc/zshrc`: macOS, macOS 26, official installer including "2.32 and higher (macOS 26b1 and
    higher)" [nd-zsh#L250-261].
  - `/etc/zprofile`: macOS, macOS 26 [nd-zsh#L244-248].
  - `/etc/zshenv`: Determinate, Rust installer 2.33.3 [nd-zsh#L263-266].
  - `/etc/bashrc`: macOS, official installer including 2.32+ [nd-bash#L103-109].
  - `/etc/nix/nix.custom.conf` is checked separately and aborts with
    `sudo mv /etc/nix/nix.custom.conf{,.before-nix-darwin}` [nd-nix#L889-937].
  - `programs.zsh.enable` and `programs.bash.enable` default to true in nix-darwin, so all of
    these files are managed.
- **On helios, all five files were renamed automatically** [local].
  `zshrc.before-nix-darwin` and `zprofile.before-nix-darwin` are dated 2026-08-13: a macOS
  update restored the stock files, and the next switch moved them aside again.
- **Manual fallback**, only if activation lists a file:
  `sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin` (and the same for each file listed), then
  re-run the switch.

### 2.6 First activation

- **Root is required.** Since 2025-01-30 "`darwin-rebuild` must now be run as root", and options
  that used to apply to the invoking user now apply to `system.primaryUser` [nd-changelog#L41-63].
  `darwin-rebuild switch` exits with "system activation must now be run as root" otherwise
  [nd-rebuild#L149-152]. The README's install command is
  `sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch` [nd-readme#L84-93].
- **Experimental-features flag:** needed on the outer `nix` only. root reads the installer's
  `nix.conf`, which has no flakes. `darwin-rebuild` itself always passes
  `--extra-experimental-features 'nix-command flakes'` [nd-rebuild#L154].
- **Name the Host explicitly.** Without `#helios`, `darwin-rebuild` uses `scutil --get
LocalHostName` [nd-rebuild#L163-172]. That is the factory name until this config sets it
  (`modules/flake/configurations.nix`).
- **Quote the flake reference.** **Assessment:** with zsh's `EXTENDED_GLOB`, `#` is a glob
  operator. `"$HOME/nix-config#helios"` is safe in any shell.
- **Final command:**
  ```sh
  sudo nix --extra-experimental-features 'nix-command flakes' \
    run nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
    switch --flake "$HOME/nix-config#helios"
  ```
  `nix-darwin` resolves through the global flake registry to `github:nix-darwin/nix-darwin`
  [registry]. That only picks the `darwin-rebuild` script. The system itself is built from this
  repo's `flake.lock`.
- **Root reading a repo owned by `ety` works.** helios has run `sudo darwin-rebuild switch
--flake ~/nix-config` 15 times [local].
- **nixbld IDs match.** With `system.stateVersion = 6`, nix-darwin expects `nixbld` GID 350
  [nd-ids#L46], which is what the official script creates [nix-darwin-multi#L16-17]. So the
  "mismatching GID" check passes [nd-checks#L104-127].

### 2.7 After the first switch

- **Open a new terminal.** Home Manager's session variables (`NH_FLAKE` and others) are sourced
  from the HM-managed zsh files [hm-nh#L109-115] [hm-darwin-doc#L55-66]. Check with
  `darwin-version`, `nh --version` and `echo $NH_FLAKE`. From then on, use `nh darwin switch`
  (CLAUDE.md).
- **Touch ID for sudo** works right away. `touch-id.nix` writes `/etc/pam.d/sudo_local`. It only
  needs a fingerprint enrolled in System Settings.
- **SSH key:** run `ssh-keygen -t ed25519 -C ety@helios`. Then replace the key under
  `users.users.ety.openssh.authorizedKeys.keys` in `modules/users/ety.nix`. It is today's helios
  key (`SHA256:uGuHLf…`) [local], and it is typhon's only way in over SSH (`ssh.nix` turns off
  passwords and root login).
- **`gh auth login`:** run it _after_ the first switch. HM's `programs.gh` installs the git
  credential helper for `https://github.com` by default [hm-gh#L121-129], so HTTPS pushes then
  work. The token in `~/.config/gh/hosts.yml` stays unmanaged (`gh.nix`). If you run it before
  the switch, HM backs up the `config.yml` that gh wrote (`*.home-manager.backup`), as happened on
  helios [local].
- **macOS privacy grants cannot be declared.** nix-darwin has no TCC option. Apple's Privacy
  Preferences payload needs device management with supervision, and for Camera, Microphone and
  Screen Recording it can only _deny_ [apple-pppc]. Grant them by hand when prompted. What helios
  has today [local: TCC.db, read-only]:
  - **Accessibility:** CapsLockNoDelay, Vorssaint.
  - **Screen Recording:** OBS, Vorssaint, Discord, Teams, VS Code.
  - **Camera/Mic:** Discord, WhatsApp, Firefox (prompted on first use).
  - **Full Disk Access:** Terminal, VS Code (optional).
  - `tailscale-app` needs its system extension approved under Privacy & Security
    [local: cask caveat]. Then sign in to Tailscale and NordVPN.
- **App Management:** if `darwin-rebuild` ever says it cannot update apps, grant your terminal
  App Management [nd-apps#L10-57]. On a blank Mac, `/Applications/Nix Apps` starts empty, so the
  first switch does not trigger this.

### 2.8 stateVersion on a new Mac

- **nix-darwin:** `system.stateVersion` selects option defaults "in a way incompatible with
  stateful data" [nd-version#L34-48]. The maximum is 7 [nd-version#L54]. At this revision the only
  behaviour gated between 6 and 7 is tmux's split bindings [nd-tmux#L62] [nd-changelog#L1-10].
  `nixbld` GID 350 applies at 5 and above [nd-ids#L46].
- **Home Manager:** "The `stateVersion` should remain set to the Home Manager release you first
  used for this home configuration" [hm-upgrading#L150-151]. Defaults that differ for 24.11
  include `linkApps`/`copyApps` [hm-copyapps#L17]. The config already overrides those
  (`mac-apps.nix`), as well as git signing (`git.nix`).
- **Assessment:**
  - **New Mac that replaces helios** (same Host, restored home): keep both values. That is exactly
    what they are for, and CLAUDE.md requires it.
  - **Second Mac alongside helios:** give it its own Host with its own values (e.g. `7` and
    `"26.05"`), rather than copying helios's pins.

### 2.9 Other pre-existing state the config assumes

- **`~/.colima/ssh_config`:** `programs.ssh.includes` points at it. It exists only after
  `colima start`. A missing `Include` is ignored silently [local: `ssh -G` test with a
  nonexistent include]. No action needed.
- **Pre-existing dotfiles:** any `~/.zshrc` or similar is backed up with `.home-manager.backup`
  rather than blocking activation (`home-manager.nix`).
- **Accounts and logins:** Firefox, VS Code, Obsidian vaults, app logins and the Tailscale tailnet
  are unmanaged.
- **Data:** restoring it (Time Machine, iCloud, projects) is out of scope.

### 2.10 Checklist draft (helios)

1. In Setup Assistant, create an admin account with account name **`ety`**. Turn on FileVault,
   install macOS updates and enroll Touch ID.
2. Install Nix (official, multi-user):
   ```sh
   curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
   ```
   Close the terminal and open a new one. Check with `nix --version`.
3. Install Homebrew (also installs the Xcode CLT and `git`). Skip its "Next steps":
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
4. Clone the config:
   ```sh
   git clone --branch develop https://github.com/Ety0011/nix-config.git ~/nix-config
   ```
5. First switch (enter your password, and again for `.pkg` casks):
   ```sh
   sudo nix --extra-experimental-features 'nix-command flakes' \
     run nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
     switch --flake "$HOME/nix-config#helios"
   ```
   If it stops with "Unexpected files in /etc", run
   `sudo mv /etc/<file> /etc/<file>.before-nix-darwin` for each listed file, then repeat step 5.
6. Open a new terminal. Run `darwin-version`, `nh --version` and `echo $NH_FLAKE`, which should
   print `/Users/ety/nix-config`.
7. `gh auth login` (GitHub.com, HTTPS, browser).
8. `ssh-keygen -t ed25519 -C ety@helios`. If the key is new, paste `~/.ssh/id_ed25519.pub` into
   `modules/users/ety.nix` (typhon's authorized key), then commit, push and `nh os switch` on
   typhon.
9. Grant Accessibility (CapsLockNoDelay, Vorssaint) and Screen Recording (OBS, Vorssaint, plus
   Discord/Teams/VS Code when they ask). Approve the Tailscale system extension, then sign in to
   Tailscale and NordVPN.
10. From now on: edit, then `nh darwin switch`.

---

## 3. typhon (x86_64-linux, NixOS 26.05)

### 3.1 Booting the target so nixos-anywhere can reach it

- **Use the NixOS installer on USB.** For a machine with no OS, nixos-anywhere says to boot the
  standard NixOS installer from USB or netboot. If `/etc/os-release` has
  `VARIANT_ID=installer`, it skips kexec [nxa-no-os#L1-19] [nxa-src#L700-701]
  [nxa-facts#L11]. Use the 26.05 minimal ISO:
  `https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso` (a `.sha256`
  file sits next to it) [local: HTTP 302 → `nixos-minimal-26.05.12707…`].
- **Writing the stick on macOS:** `diskutil list`, `diskutil unmountDisk diskX`,
  `sudo dd if=<iso> of=/dev/rdiskX bs=4m`, `diskutil eject /dev/diskX` [nixos-usb#L40-72].
- **Firmware:** choose UEFI boot. "You will likely need to disable Secure Boot"
  [nixos-install#L33-34].
- **SSH access:** the installer runs sshd with `PermitRootLogin = "yes"`. `nixos` and `root` have
  empty passwords, so "to log in over ssh you must set a password for either nixos or root with
  passwd (prefix with sudo for root)" [nixos-iso#L36-49,L65-71,L84-87]. With `root@<ip>`,
  nixos-anywhere uses that password once to `ssh-copy-id` your key, then works by key
  [nxa-src#L533-571]. With `nixos@<ip>` it copies the key over to root itself
  [nxa-src#L1037-1042].
- **Network: use Ethernet.** nixos-anywhere "does not support wifi networks" [nxa-readme#L80].
- **RAM:** at least 1.5 GB [nxa-req#L38-39].

### 3.2 Flags, checked against the source

- **Phases.** `--phases` defaults to `kexec,disko,install,reboot` [nxa-ref#L84-89].
  `kexec,disko,install` leaves `/mnt` mounted for the `passwd` step: the reboot phase only
  unmounts for ZFS [nxa-src#L921-935].
- **`kexec` phase on the installer.** Keeping `kexec` in the list does no harm on the installer
  (`runKexec` returns early). Dropping it would make nixos-anywhere assume kexec already ran and
  switch to `root@` [nxa-src#L983-986].
- **`--disk-encryption-keys <remote_path> <local_path>`** copies the file or pipe to the remote
  path before disko runs [nxa-ref#L64-66] [nxa-src#L843-848].
  - `/tmp/secret.key` matches `passwordFile` in `_disko.nix`.
  - disko reads it with `echo -n "$(cat …)"`, so a trailing newline does not matter
    [disko-luks#L25-28].
  - The docs show both a plain file and `<(pass …)` [nxa-secrets#L48-58].
- **`--generate-hardware-config nixos-facter <path>`** is correct syntax [nxa-ref#L81-83].
  - It runs `nixos-facter` on the target, through `nix shell nixpkgs#nixos-facter` if the
    installer lacks it, and writes the report locally [nxa-src#L660-685].
  - It then runs `git add --intent-to-add --force` on the file, so the flake can see it
    [nxa-src#L687-697]. You do not `git add` it by hand before the run, but you must commit it
    afterwards.
- **Build location.** helios is aarch64-darwin, so `--build-on auto` falls back to building on
  the target [nxa-src#L617-657,L1018-1025].
- **Order inside nixos-anywhere:** hardware report → build → disko → install [nxa-src#L1013-1066].
  So a config that already says `hardware.facter.reportPath = ./facter.json` is built _with_ the
  new report. The early probe that evaluates the flake swallows the error while the file is
  missing [nxa-src#L625-629]. This is the flow the quickstart describes: "include an import for
  the hardware configuration beforehand" [nxa-quickstart#L148-206].
- **Facter does not replace the boot loader.** It sets `nixpkgs.hostPlatform`, firmware,
  microcode, initrd modules, graphics, networking and bluetooth [nixpkgs-facter-md#L46-57]. For
  boot it only sets `grub.efiSupport` [nixpkgs-facter-boot]. systemd-boot, EFI variables and zram
  must stay in `_hardware.nix`.
- **Root after the install:** nixos-anywhere installs with `nixos-install --no-root-passwd`
  [nxa-src#L916]. `ssh.nix` disables root login and passwords. So `ety` needs a password set
  before reboot (console login), plus helios's key (SSH). The NixOS manual gives the same
  command: `nixos-enter --root /mnt -c 'passwd alice'` [nixos-install#L470-476].
- **Disk device.** disko's examples use `/dev/disk/by-id/…` [disko-howto#L140].
  **Assessment:** use the by-id path rather than `/dev/nvme0n1`, whose numbering can change if a
  second NVMe drive is added.
- **Privacy of `facter.json`.** It goes into a public repo. nixos-facter leaves board and chassis
  serial numbers out of its JSON [facter-board#L17] [facter-chassis#L16], and skips ephemeral data
  unless you pass `--ephemeral` [facter-root#L35-36].

### 3.3 Checklist draft (typhon)

On helios:

1. Download and write the installer:
   ```sh
   curl -LO https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso
   diskutil list                      # find the USB stick, e.g. disk4
   diskutil unmountDisk disk4
   sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/rdisk4 bs=4m
   diskutil eject /dev/disk4
   ```

On typhon:

2. In the firmware, select UEFI and turn Secure Boot off. Plug in Ethernet and boot the USB stick.
3. At the installer prompt:
   ```sh
   sudo passwd          # temporary root password for the installer only
   ip -brief addr       # note the IP
   ```

On helios, in `~/nix-config`:

4. Find the disk:
   ```sh
   ssh root@<ip> 'lsblk -d -o NAME,SIZE,MODEL; ls -l /dev/disk/by-id/ | grep -v part'
   ```
   Set `device = "/dev/disk/by-id/nvme-…";` in `modules/hosts/typhon/_disko.nix`.
5. In `modules/hosts/typhon/_hardware.nix`, **add** `hardware.facter.reportPath = ./facter.json;`.
   Keep the systemd-boot, EFI and zram lines.
6. Write the LUKS passphrase to a private temp file (typed twice, not echoed):
   ```sh
   umask 077; printf 'LUKS passphrase: '; IFS= read -rs p1; echo
   printf 'Again: '; IFS= read -rs p2; echo
   [ "$p1" = "$p2" ] && printf %s "$p1" > /tmp/typhon-luks.key; unset p1 p2
   ```
7. Install (wipes the disk):
   ```sh
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#typhon \
     --target-host root@<ip> \
     --generate-hardware-config nixos-facter ./modules/hosts/typhon/facter.json \
     --disk-encryption-keys /tmp/secret.key /tmp/typhon-luks.key \
     --phases kexec,disko,install
   ```
8. Set ety's password, then reboot:
   ```sh
   ssh -t root@<ip> "nixos-enter --root /mnt -c 'passwd ety'"
   ssh root@<ip> reboot
   rm /tmp/typhon-luks.key
   ```
9. Commit the result:
   ```sh
   git add modules/hosts/typhon/{facter.json,_disko.nix,_hardware.nix}
   git commit -m "feat(typhon): disk id and facter report"
   git push
   ```

On typhon, after the first boot:

10. Type the LUKS passphrase, then log in as `ety` at SDDM. From helios, run
    `ssh-keygen -R <ip>` (the host key changed), then `ssh ety@<ip>`.
11. On typhon:
    ```sh
    git clone https://github.com/Ety0011/nix-config.git ~/nix-config
    gh auth login
    sudo tailscale up
    ```
    Future changes: `nh os switch`.

---

## 4. Corrections to `modules/hosts/typhon/default.nix`

The header comment is right about the tool, `.#typhon`, `--disk-encryption-keys /tmp/secret.key`,
the facter flag syntax, the phases and `nixos-enter … passwd ety`. What to change:

1. **Missing: how to get a reachable installer.** Boot the NixOS 26.05 minimal ISO (UEFI,
   Secure Boot off, Ethernet), then run `sudo passwd`. Without it, `root@<installer-ip>` cannot log
   in [nixos-iso#L65-71].
2. **`ssh root@<ip> nixos-enter … 'passwd ety'` needs `ssh -t`.** **Assessment:** `passwd`
   prompts on a terminal, and `ssh host cmd` allocates none, so the prompt fails or echoes.
3. **Facter is wired too late.**
   - The comment installs with the placeholder `_hardware.nix` and wires the report in afterwards,
     so the first boot runs without facter's firmware, microcode and initrd modules. NixOS's
     default initrd modules (nvme, ahci, xhci, usbhid) probably still boot it
     [nixpkgs-kernel#L326-366].
   - Add `hardware.facter.reportPath = ./facter.json;` before step 2, as the nixos-anywhere
     quickstart says [nxa-quickstart#L153-206].
   - "Replace `_hardware.nix` with the facter report" is wrong: keep the boot loader and zram lines
     [nixpkgs-facter-boot]. `_hardware.nix`'s own header comment says the same and needs the same
     fix.
4. **The passphrase input** `<(read -s p; printf %s "$p")` shows no prompt. It reads the terminal
   at the same moment `ssh-copy-id` asks for the root password, and it takes the passphrase once
   with no confirmation. **Assessment:** read it into a `umask 077` temp file first, confirmed
   twice (§3.3 step 6), and pass that file.
5. **Missing after-steps:**
   - Commit `facter.json` together with the disk id: nixos-anywhere only `git add
--intent-to-add`s it [nxa-src#L687-697].
   - Remove the temporary key file.
   - `ssh-keygen -R <ip>` on helios.
   - Clone the repo to `~/nix-config` on typhon for `nh os switch`.
   - Optional: use a `/dev/disk/by-id/` path in `_disko.nix`, whose header comment also says
     "`lsblk`".

Suggested replacement header:

```nix
# Install from helios (see docs/research/rebuild-from-zero.md §3.3):
#   1. Boot the NixOS 26.05 minimal ISO (UEFI, Secure Boot off, Ethernet); on it run
#      `sudo passwd` and `ip -brief addr`.
#   2. Set `device` in _disko.nix from `ssh root@<ip> ls -l /dev/disk/by-id/`, and add
#      `hardware.facter.reportPath = ./facter.json;` to _hardware.nix.
#   3. Put the LUKS passphrase in /tmp/typhon-luks.key (umask 077), then:
#        nix run github:nix-community/nixos-anywhere -- --flake .#typhon \
#          --target-host root@<ip> \
#          --generate-hardware-config nixos-facter ./modules/hosts/typhon/facter.json \
#          --disk-encryption-keys /tmp/secret.key /tmp/typhon-luks.key \
#          --phases kexec,disko,install
#   4. ssh -t root@<ip> "nixos-enter --root /mnt -c 'passwd ety'"; ssh root@<ip> reboot
#   5. git add + commit facter.json, _disko.nix, _hardware.nix; rm /tmp/typhon-luks.key.
```

---

## 5. Limitations

- **Nothing was run.** No installer, switch or install was executed. The checklists are drawn
  from source and docs plus helios's own history, not from a dry run on blank hardware.
- **macOS 27.** The known `/etc` hashes in nix-darwin 26.05 (and in `master` today) stop at
  macOS 26. If a newer macOS changes the stock `/etc/zshrc`, `/etc/zprofile` or `/etc/bashrc`, the
  manual rename in §2.5 will be needed. helios runs macOS 26.6.2 [local].
- **Unpinned commands.** The Nix script (now 2.35.4) and the Homebrew script are fetched from
  moving URLs. `nix run github:nix-community/nixos-anywhere` and
  `nix-darwin/nix-darwin-26.05#darwin-rebuild` follow branch heads, not `flake.lock`. The last
  nixos-anywhere release is 1.13.0 (2025-11-13); `main` is what I read.
- **`ssh -t` (§4.2) is reasoning, not tested.** Neither is the claim that the placeholder
  hardware config would still boot.
- **Branch.** helios runs `develop`, not `main`. If `develop` is merged, drop `--branch develop`.
- **`facter.json` contents.** I checked that board and chassis serials are left out. I did not
  check every field; skim the file before pushing it to the public repo.

---

## 6. Sources

nix-darwin @ `d31953cf55f9027a56e9be938daf5db8c5655663` (nix-darwin-26.05)

- [nd-etc] https://github.com/nix-darwin/nix-darwin/blob/d31953cf55f9027a56e9be938daf5db8c5655663/modules/system/etc.nix (L42-91, L112)
- [nd-nix] …/modules/nix/default.nix (L743-761, L889-937) · [nd-nixconf] same file, L743-761
- [nd-zsh] …/modules/programs/zsh/default.nix (L19-22, L244-266) · [nd-bash] …/modules/programs/bash/default.nix (L103-109)
- [nd-checks] …/modules/system/checks.nix (L34-44, L47-60, L104-127)
- [nd-rebuild] …/pkgs/nix-tools/darwin-rebuild.sh (L1-8, L149-154, L163-172)
- [nd-changelog] …/CHANGELOG (L1-10, L41-63)
- [nd-users] …/modules/users/default.nix (L61-68)
- [nd-brew] …/modules/homebrew.nix (L653-659, L681-689, L857-871, L980-982, L1022-1035)
- [nd-version] …/modules/system/version.nix (L34-54) · [nd-tmux] …/modules/programs/tmux.nix (L62) ·
  [nd-ids] …/modules/misc/ids.nix (L46)
- [nd-apps] …/modules/system/applications.nix (L10-57)
- [nd-readme] https://github.com/nix-darwin/nix-darwin/blob/bb0b90dbd54e207100de72b5dcbe3188c98a4b69/README.md
  (L12-18, L84-93; the 26.05 branch README only links to `master`'s)

home-manager @ `24f2190587513b9c2f73db112a17844ae912d965` (release-26.05)

- [hm-upgrading] https://github.com/nix-community/home-manager/blob/24f2190587513b9c2f73db112a17844ae912d965/docs/manual/usage/upgrading.md (L147-166)
- [hm-version] …/modules/misc/version.nix (L11-41) · [hm-copyapps] …/modules/targets/darwin/copyapps.nix (L17)
- [hm-nh] …/modules/programs/nh.nix (L109-115) · [hm-gh] …/modules/programs/gh.nix (L121-129)
- [hm-darwin-doc] …/docs/manual/installation/nix-darwin.md (L55-66)

nixpkgs @ `1f607aa79b6356ed45d3cd3c8079c196e79efa2c` (nixos-26.05)

- [nixos-iso] https://github.com/NixOS/nixpkgs/blob/1f607aa79b6356ed45d3cd3c8079c196e79efa2c/nixos/modules/profiles/installation-device.nix (L36-71, L84-87)
- [nixos-install] …/nixos/doc/manual/installation/installing.chapter.md (L33-34, L160-171, L470-482)
- [nixos-usb] …/nixos/doc/manual/installation/installing-usb.section.md (L40-72)
- [nixpkgs-facter-md] …/nixos/modules/hardware/facter/facter.md (L46-57) · [nixpkgs-facter-boot] …/nixos/modules/hardware/facter/boot.nix
- [nixpkgs-kernel] …/nixos/modules/system/boot/kernel.nix (L326-366)

disko @ `cedd626e11b635470fa6f9fdb8ad79b0075dd7f9`

- [disko-luks] https://github.com/nix-community/disko/blob/cedd626e11b635470fa6f9fdb8ad79b0075dd7f9/lib/types/luks.nix (L19-38)
- [disko-howto] …/docs/HowTo.md (L140)

nixos-anywhere @ `92b94751fc010eab62d07de40972cffa6937cafd`

- [nxa-src] https://github.com/nix-community/nixos-anywhere/blob/92b94751fc010eab62d07de40972cffa6937cafd/src/nixos-anywhere.sh
  (L533-571, L617-657, L660-697, L700-701, L843-848, L863-919, L921-935, L937-1072)
- [nxa-facts] …/src/get-facts.sh (L11, L22) · [nxa-ref] …/docs/reference.md (L21-102)
- [nxa-quickstart] …/docs/quickstart.md (L120-246) · [nxa-no-os] …/docs/howtos/no-os.md (L1-71)
- [nxa-secrets] …/docs/howtos/secrets.md (L41-63) · [nxa-readme] …/README.md (L46-82) ·
  [nxa-req] …/docs/requirements.md (L24, L38-39)

nixos-facter @ `301b533c0542501a9a85e3dfd580d87527418d59`

- [facter] https://github.com/nix-community/nixos-facter/blob/301b533c0542501a9a85e3dfd580d87527418d59/README.md (L22-40)
- [facter-root] …/cmd/root.go (L35-36) · [facter-board] …/pkg/hwinfo/smbios_board.go (L17) ·
  [facter-chassis] …/pkg/hwinfo/smbios_chassis.go (L16)

Nix installers

- [nixos-download] https://nixos.org/download/ (macOS section, read 2026-10-27)
- [nix-install-sh] https://nixos.org/nix/install (L84: `nix-2.35.4`, read 2026-10-27)
- [nix-tarball] https://github.com/NixOS/nix/blob/2.35.4/scripts/install-nix-from-tarball.sh (L30-42, L49-70, L94)
- [nix-multi] https://github.com/NixOS/nix/blob/2.35.4/scripts/install-multi-user.sh (L38, L998-1004)
- [nix-darwin-multi] https://github.com/NixOS/nix/blob/2.35.4/scripts/install-darwin-multi-user.sh (L16-17)
- [nix-volume] https://github.com/NixOS/nix/blob/2.35.4/scripts/create-darwin-volume.sh (L75-84)
- [nix-xp] https://github.com/NixOS/nix/blob/2.35.4/src/libutil/experimental-features.cc (L77-80, L100-103)
- [nixos-installer] https://github.com/NixOS/nix-installer/blob/f6f7c8d4788f64c19aa7523670fdf3bd4d4de58d/README.md (L3-31, L348, L370)
- [detsys] https://github.com/DeterminateSystems/nix-installer/blob/35c6f8eb91d4ec1292cf24f48bde97c5183279a1/README.md (L9-15, L389, L435-452)
- [registry] https://github.com/NixOS/flake-registry/blob/46ea0f17cf6777e156a2be6ae802d9f95d93dd5e/flake-registry.json (`nix-darwin` entry)

Homebrew and Apple

- [brew-installation] https://github.com/Homebrew/brew/blob/a59d9fc5f8361dccde817ce1c066fdf365c8df3e/docs/Installation.md (L36-42, L98-101, L138) · https://docs.brew.sh/Installation
- [brew-install] https://github.com/Homebrew/install/blob/85d1a3fc80d8a63932f632aca8f787de11d14a64/install.sh (L446-452, L783, L888-920, L1137-1154)
- [apple-pppc] https://support.apple.com/guide/deployment/privacy-preferences-policy-control-payload-dep38df53c2a/web
  (supervision required; Camera, Microphone, Screen recording: "deny" only)

Local

- [local] Read-only commands on helios, 2026-10-27:
  - Nix install: `nix --version`, `ls /nix/receipt.json`, `/etc/nix/*`, `shasum -a 256` of
    `/etc/*.before-nix-darwin` and `*.backup-before-nix`, `/Library/LaunchDaemons/org.nixos.*`,
    the root profile `manifest.nix`.
  - Users and system: `dscl` (nixbld, `_nixbld1`, `ety`, `admin`), `fdesetup status`,
    `xcode-select -p`, `sw_vers`.
  - Config and history: `darwin-version --configuration-revision`, zsh history (only lines with
    `darwin-rebuild` or `nix run`).
  - Apps and grants: `brew info --json=v2 --cask …`, `lipo -archs` on the installed apps, TCC.db
    (read-only `sqlite3`).
  - SSH: an `ssh -G` test of a missing `Include`, `ssh-keygen -lf ~/.ssh/id_ed25519.pub`.
  - Repo: `nix flake metadata`, `git branch -a`.
