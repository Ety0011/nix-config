{
  inputs,
  lib,
  self,
  ...
}:
{
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
    description = "Shared helper functions for building host and user configurations.";
  };

  config.flake.lib = {

    mkNixos = system: hostName: {
      ${hostName} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.common.base
          inputs.self.modules.nixos.base
          inputs.self.modules.nixos.${hostName}
          {
            nixpkgs.hostPlatform = system;
            networking.hostName = hostName;
          }
        ];
      };
    };

    mkDarwin = system: hostName: {
      ${hostName} = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          inputs.self.common.base
          inputs.self.modules.darwin.base
          inputs.self.modules.darwin.${hostName}
          {
            nixpkgs.hostPlatform = system;
            networking.hostName = hostName;
            networking.computerName = hostName;
          }
        ];
      };
    };

    mkUser = username: isAdmin: {
      nixos.${username} =
        { lib, pkgs, ... }:
        {
          users.users.${username} = {
            isNormalUser = true;
            home = "/home/${username}";
            extraGroups =
              [ "networkmanager" ]
              ++ lib.optionals isAdmin [ "wheel" ];
            shell = pkgs.zsh;
          };
          programs.zsh.enable = true;
          home-manager.users.${username}.imports = [
            self.modules.homeManager.${username}
          ];
        };

      darwin.${username} =
        { lib, pkgs, ... }:
        {
          users.users.${username} = {
            name = username;
            home = "/Users/${username}";
            shell = pkgs.zsh;
          };
          system.primaryUser = lib.mkIf isAdmin username;
          programs.zsh.enable = true;
          home-manager.users.${username}.imports = [
            self.modules.homeManager.${username}
          ];
        };

      homeManager.${username} = {
        imports = [ self.modules.homeManager.base ];
        home.username = username;
      };
    };

  };
}
