{ ... }:
{
  # Hardware / platform configuration for Etiennes-MacBook-Pro (Apple Silicon).
  # hostPlatform is also set by lib.mkDarwin as a mkDefault, so this takes
  # precedence only if explicitly needed.
  flake.modules.darwin.mac-machine = {
    nixpkgs.hostPlatform = "aarch64-darwin";
  };
}
