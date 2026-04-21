{
  inputs,
  lib,
  ...
}:
{
  # Expose helper functions via flake.lib so host flake-parts files stay
  # as one-liners and never repeat the darwinSystem / nixosSystem boilerplate.

  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
    description = "Shared helper functions for building host configurations.";
  };

  config.flake.lib = {

    # Build a nixosConfiguration from the matching flake.modules.nixos.<name> module.
    # Usage:  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "my-host";
    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    # Build a darwinConfiguration from the matching flake.modules.darwin.<name> module.
    # Usage:  flake.darwinConfigurations = inputs.self.lib.mkDarwin "aarch64-darwin" "my-host";
    mkDarwin = system: name: {
      ${name} = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

  };
}
