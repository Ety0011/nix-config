{ lib, config, ... }:
let
  profiles = config.users.profiles;
in
{
  flake.modules.homeManager = lib.genAttrs (lib.attrNames profiles) (
    username:
    { pkgs, ... }:
    lib.mkIf (profiles.${username}.features.nixTools.enable) {
      home.packages = with pkgs; [
        nixd
        nixfmt-rfc-style
      ];
    }
  );
}
