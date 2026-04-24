{ inputs, ... }:
{
  flake.modules.darwin."Etiennes-MacBook-Pro" = {
    imports = with inputs.self.modules.darwin; [
      host-desktop  # host-base (nix settings, GC, home-manager, sops)
                    # + system-defaults + window-manager
    ];

    networking.hostName = "Etiennes-MacBook-Pro";
    networking.computerName = "Etiennes-MacBook-Pro";
  };
}
