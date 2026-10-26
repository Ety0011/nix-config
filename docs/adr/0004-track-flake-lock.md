# Track flake.lock in git

`flake.lock` is committed and updated by hand (`nix flake update`, then switch, then commit). This reverses the old "Stop tracking all flake.lock files" (`1d41f56`): without a committed lock, CI and typhon resolve inputs fresh and build different versions than helios runs, and checking out an old commit no longer reproduces its packages. Lock bumps stay manual; no bot opens update PRs.
