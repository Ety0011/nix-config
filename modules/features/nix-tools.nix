{
  flake.modules.darwin.base.home-manager.sharedModules = [
    { programs.zsh.shellAliases.update = "sudo darwin-rebuild switch --flake ~/nix-config"; }
  ];
  flake.modules.nixos.base.home-manager.sharedModules = [
    { programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake ~/nix-config"; }
  ];

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nixd
        nixfmt
      ];
    };
}
