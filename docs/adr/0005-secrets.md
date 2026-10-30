# Secrets: sops-nix at system level, post-quantum age keys

Secrets the config needs (the NAS login for backup-home now; on typhon later, restic and Syncthing) are encrypted with sops into `secrets/<host>.yaml` and decrypted at activation by sops-nix's nix-darwin and NixOS modules, each secret owned by the User that reads it. Home Manager modules take the paths from `osConfig.sops.secrets.<name>.path`; sops-nix's own Home Manager module is not used. Every recipient is a native post-quantum age key (`age-keygen -pq`): one per Host plus a recovery key whose private half lives only in Apple Passwords.

On darwin, sops-nix keeps decrypted secrets on a RAM disk and installs them all-or-nothing, so a failed decrypt keeps the previous set; `nix flake check` catches a declared secret missing from its file without any key, so public CI still works. The repo is public, so its ciphertext stays readable in git history forever: only post-quantum recipients resist "collect now, decrypt later", and sops silently accepts a mix in which the file is only as strong as its classic recipient. The evidence is in `docs/research/secrets.md`.

## Considered Options

- **agenix:** smaller, and age itself refuses to mix post-quantum and classic recipients. But one file per secret, no templates, and its darwin Home Manager agent writes to disk and has an open restart-loop bug (ryantm/agenix#372).
- **sops-nix's Home Manager module:** the part with open darwin activation bugs (Mic92/sops-nix#997, #910, #801); the system modules with `owner` do the same job.
- **Age keys derived from SSH keys (`ssh-to-age`):** Ed25519 is not post-quantum, and a passphrase on the SSH key would break decryption at activation.
- **macOS Keychain:** right for per-device interactive credentials, but not declarative and absent on typhon.
- **Private secrets repo as a flake input:** hides secret names, but fetching it needs a token on every Host and public CI can no longer evaluate.

## Consequences

- Keys: helios at `~/Library/Application Support/sops/age/keys.txt` (0600), typhon at `/var/lib/sops-nix/key.txt` (root 0600, copied in at install). Host keys are per device and stay out of backup-home, like SSH keys.
- Recovery: on a new Host, make a new key, swap its recipient into `.sops.yaml`, and run `SOPS_AGE_KEY="<recovery key>" sops updatekeys secrets/*.yaml`. If a key leaks, change the secret values, then `sops updatekeys` and `sops rotate`; old commits stay readable to the leaked key. If both a Host key and the recovery key are lost, every secret must be reset at its source.
- Secret names and recipients are public plaintext in the YAML: use neutral names (`nas-pass`, not the NAS address).
- Kept out of sops: the gh token (keychain), SSH private keys and their passphrase (per device, Keychain), typhon's LUKS passphrase (typed at boot), typhon's login password (set once with `passwd`), app logins and macOS Wi-Fi.
