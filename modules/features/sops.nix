# sops-nix at system level only: at activation it decrypts secrets/<host>.yaml
# into /run/secrets (a RAM disk on darwin). Home Manager modules read secret
# paths through osConfig. Inert until a Host declares sops.secrets.
# Keys and recovery: docs/adr/0005.
{ inputs, ... }:
{
  flake.modules.darwin.base = {
    imports = [ inputs.sops-nix.darwinModules.sops ];
    # Native post-quantum age keys only, never SSH keys.
    sops.age.sshKeyPaths = [ ];
    sops.gnupg.sshKeyPaths = [ ];
  };

  flake.modules.nixos.base = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";
    sops.age.sshKeyPaths = [ ];
    sops.gnupg.sshKeyPaths = [ ];
  };

  # `sops edit` and `age-keygen` for editing secrets and making keys.
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.age
        pkgs.sops
      ];
    };
}
