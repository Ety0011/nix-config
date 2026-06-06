{
  lib,
  config,
  inputs,
  self,
  withSystem,
  ...
}:
let
  darwinHosts = lib.filterAttrs (_: v: v.platform == "darwin") config.hosts;
  nixosHosts = lib.filterAttrs (_: v: v.platform == "nixos") config.hosts;
  userNames = lib.attrNames config.users.profiles;
  darwinFeatures = lib.attrValues (
    lib.filterAttrs (n: _: !(lib.elem n userNames)) self.modules.darwin
  );
  nixosFeatures = lib.attrValues (lib.filterAttrs (n: _: !(lib.elem n userNames)) self.modules.nixos);
in
{
  config.flake.darwinConfigurations = lib.mapAttrs (
    hostName: hostCfg:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {
        hostProfiles = lib.filterAttrs (n: _: lib.elem n hostCfg.activeUsers) config.users.profiles;
      };
      modules =
        darwinFeatures
        ++ map (u: self.modules.darwin.${u}) hostCfg.activeUsers
        ++ [
          {
            nixpkgs.hostPlatform = hostCfg.system;
            nixpkgs.pkgs = withSystem hostCfg.system ({ pkgs, ... }: pkgs);
            networking.hostName = hostName;
            networking.computerName = hostName;
            system.stateVersion = hostCfg.stateVersion;
            system.configurationRevision = self.rev or self.dirtyRev or null;
            nix.registry.nixpkgs.flake = inputs.nixpkgs-darwin;
          }
        ];
    }
  ) darwinHosts;

  config.flake.nixosConfigurations = lib.mapAttrs (
    hostName: hostCfg:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        hostProfiles = lib.filterAttrs (n: _: lib.elem n hostCfg.activeUsers) config.users.profiles;
      };
      modules =
        nixosFeatures
        ++ map (u: self.modules.nixos.${u}) hostCfg.activeUsers
        ++ [
          {
            nixpkgs.hostPlatform = hostCfg.system;
            nixpkgs.pkgs = withSystem hostCfg.system ({ pkgs, ... }: pkgs);
            networking.hostName = hostName;
            system.stateVersion = hostCfg.stateVersion;
            nix.registry.nixpkgs.flake = inputs.nixpkgs;
          }
        ];
    }
  ) nixosHosts;
}
