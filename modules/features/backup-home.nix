# Daily mirror of ~ to the NAS (_backup-home.nix). One-off: a Host imports
# `darwin.backup-home` when its secrets/<host>.yaml holds the NAS login.
{
  flake.modules.darwin.backup-home =
    { config, lib, ... }:
    let
      user = config.system.primaryUser;
    in
    {
      sops.secrets = lib.genAttrs [ "nas-host" "nas-user" "nas-pass" ] (_: {
        owner = user;
      });
      home-manager.users.${user}.imports = [ ./_backup-home.nix ];
    };
}
