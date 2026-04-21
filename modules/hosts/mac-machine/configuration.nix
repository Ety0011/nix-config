{ inputs, ... }:
{
  flake.modules.darwin."Etiennes-MacBook-Pro" = {
    imports = with inputs.self.modules.darwin; [
      system-desktop
    ];

    networking.hostName = "Etiennes-MacBook-Pro";
    networking.computerName = "Etiennes-MacBook-Pro";
  };
}
