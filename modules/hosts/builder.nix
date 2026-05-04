{
  inputs,
  lib,
  config,
  self,
  ...
}:
let
  darwinHostModule = _: {
    options = {
      system = lib.mkOption {
        type = lib.types.str;
        default = "aarch64-darwin";
        description = "The host platform system string.";
      };

      stateVersion = lib.mkOption {
        type = lib.types.int;
        default = 6;
        description = "nix-darwin state version.";
      };

      users = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Usernames of users on this host. Each must have a corresponding darwin.<username> module.";
      };
    };
  };
in
{
  options.darwinHosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule [ darwinHostModule ]);
    default = { };
    description = "Declarative darwin host definitions.";
  };

  config.flake.darwinConfigurations =
    lib.mapAttrs
      (hostName: hostOpts:
        inputs.nix-darwin.lib.darwinSystem {
          modules =
            [
              # 1. base — universal system policy for all darwin hosts
              self.modules.darwin.base

              # 2. host — identity and platform settings
              {
                nixpkgs.hostPlatform = hostOpts.system;
                networking.hostName = hostName;
                networking.computerName = hostName;
                system.stateVersion = hostOpts.stateVersion;
              }
            ]
            # 3. users — each user module declares its own OS account,
            #    homebrew config, and home-manager wiring
            ++ map (username: self.modules.darwin.${username}) hostOpts.users;
        })
      config.darwinHosts;
}
