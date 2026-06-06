{
  inputs,
  lib,
  config,
  ...
}:
let
  profiles = config.users.profiles;
  anyWants = feat: lib.any (u: profiles.${u}.features.${feat}.enable) (lib.attrNames profiles);
in
{
  flake.modules.darwin.sops = lib.mkIf (anyWants "sops") {
    imports = [ inputs.sops-nix.darwinModules.sops ];
  };

  flake.modules.nixos.sops = lib.mkIf (anyWants "sops") {
    imports = [ inputs.sops-nix.nixosModules.sops ];
  };

  flake.modules.homeManager = lib.genAttrs (lib.attrNames profiles) (
    username:
    lib.mkIf (profiles.${username}.features.sops.enable && profiles.${username}.features.sops.allowed) {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];
    }
  );
}
