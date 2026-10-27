{
  # Lets prebuilt Linux binaries (pixi/conda packages, pip wheels, VS Code
  # server extensions) find a dynamic loader on NixOS.
  flake.modules.nixos.base.programs.nix-ld.enable = true;
}
