# nix-config

Dendritic Nix flake for two Hosts:

- `helios`: MacBook, aarch64-darwin (nix-darwin + Home Manager + Homebrew casks)
- `typhon`: desktop PC, x86_64-linux (NixOS, KDE Plasma)

Vocabulary is in [GLOSSARY.md](GLOSSARY.md), decisions in [docs/adr/](docs/adr/), research in
[docs/research/](docs/research/).

## Daily use

```sh
nh darwin switch        # helios: build and apply (typhon: nh os switch)
nh darwin build         # build and show the diff without applying
nix flake update        # bump inputs (manual, see docs/adr/0004)
nix flake check         # evaluate and build every Host
nix fmt                 # format
```

`main` is the last known-good state; work happens on `develop`.

## Rebuild helios from a blank Mac

Sources and reasoning: [docs/research/rebuild-from-zero.md](docs/research/rebuild-from-zero.md) §2.
Restoring personal data (Time Machine, iCloud) is separate.

1. In Setup Assistant, create an admin account whose **account name is `ety`** (not the
   suggested `etienne`). Turn on FileVault, install macOS updates, enroll Touch ID.
2. Install Nix (official installer, multi-user), then open a new terminal:
   ```sh
   curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
   ```
3. Install Homebrew (it also installs the Xcode Command Line Tools, which gives you `git`).
   Skip its "Next steps"; the config handles `brew shellenv`.
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
4. Clone the config. It must live at `~/nix-config`:
   ```sh
   git clone https://github.com/Ety0011/nix-config.git ~/nix-config
   ```
5. First switch. Enter your password; `.pkg` casks may ask again.
   ```sh
   sudo nix --extra-experimental-features 'nix-command flakes' \
     run nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
     switch --flake "$HOME/nix-config#helios"
   ```
   If it stops with "Unexpected files in /etc", run
   `sudo mv /etc/<file> /etc/<file>.before-nix-darwin` for each file it lists, then repeat.
6. Open a new terminal and check: `darwin-version`, `nh --version`, `echo $NH_FLAKE` (should
   print `/Users/ety/nix-config`).
7. `gh auth login` (GitHub.com, HTTPS, browser).
8. `ssh-keygen -t ed25519 -C ety@helios`, then put `~/.ssh/id_ed25519.pub` in
   `modules/users/ety.nix` (typhon's authorized key), commit and push. If typhon is installed, it no longer
   accepts the old key, so log in at its console and run `nh os switch` there.
9. Grant by hand when asked (macOS does not allow declaring these):
   - Accessibility: CapsLockNoDelay, Vorssaint
   - Screen Recording: OBS, Vorssaint (Discord, Teams, VS Code when they ask)
   - Approve the Tailscale system extension, then sign in to Tailscale and NordVPN.

From then on: edit, `nh darwin switch`.

Keep `system.stateVersion = 6` and `home.stateVersion = "24.11"` on a Mac that replaces
helios. A second Mac gets its own Host with current values.

## typhon

Not installed yet. When it's time, follow
[docs/research/rebuild-from-zero.md](docs/research/rebuild-from-zero.md) §3.3.
