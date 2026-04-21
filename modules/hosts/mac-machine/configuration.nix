{ inputs, ... }:
{
  # Defines the mac-machine darwin module.
  # Users are wired in users/ety.nix; hardware in hardware.nix.
  flake.modules.darwin.mac-machine = {
    imports = with inputs.self.modules.darwin; [
      system-desktop # layer 3: system-minimal → system-cli → system-desktop
    ];

    networking.hostName = "Etiennes-MacBook-Pro";
    networking.computerName = "Etiennes-MacBook-Pro";
  };
}
