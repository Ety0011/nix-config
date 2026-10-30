# Homebrew holds GUI apps only; cleanup uninstalls the rest

On macOS, GUI apps are Homebrew casks and CLI tools come from nixpkgs; the only brews are the Colima Docker stack. `homebrew.onActivation.cleanup = "uninstall"`, so the declared lists are the truth and anything else is removed on switch.

GUI apps such as Teams and OBS need macOS privacy grants (camera, microphone, screen recording) that are tied to the app's path and signature; a Nix-built app changes on every update and loses them. Most of these apps also update themselves, which fights a pinned store path, and some (OBS, CapsLockNoDelay) are not packaged for darwin in nixpkgs. CLI tools gain from Nix: pinned, the same on typhon, and rolled back with the system.

## Considered Options

- **Everything from nixpkgs:** loses privacy grants on each update; several apps unavailable.
- **`cleanup = "zap"`:** also deletes app preferences and data of removed casks; too destructive for a convenience.
- **nix-homebrew (Homebrew itself managed by Nix):** one tap (`pear-devs/pear`) and brew already installed; revisit for a fresh Mac.
