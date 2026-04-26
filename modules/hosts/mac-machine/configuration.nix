{ inputs, ... }:
let
  hostName = "Etiennes-MacBook-Pro";
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations = inputs.self.lib.mkDarwin system hostName;

  flake.modules.darwin.${hostName} = {
    imports = with inputs.self.modules.darwin; [ base ];
  };
}
