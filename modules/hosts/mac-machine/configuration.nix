{ inputs, ... }:
let
  hostName = "Etiennes-MacBook-Pro";
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations = inputs.self.lib.mkDarwin system hostName;

  # Hardware-specific overrides — add kernel modules or hardware quirks here if needed.
  flake.modules.darwin.${hostName} = { };
}
