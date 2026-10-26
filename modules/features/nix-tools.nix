{
  flake.modules.darwin.base.home-manager.sharedModules = [
    { programs.zsh.shellAliases.update = "nh darwin switch"; }
  ];
  flake.modules.nixos.base.home-manager.sharedModules = [
    { programs.zsh.shellAliases.update = "nh os switch"; }
  ];

  flake.modules.homeManager.base =
    { config, pkgs, ... }:
    {
      # Garbage collection stays with the system `nix.gc`; leave `programs.nh.clean` off.
      programs.nh = {
        enable = true;
        flake = "${config.home.homeDirectory}/nix-config";
      };
      home.packages = with pkgs; [
        nixd
        nixfmt
      ];
    };
}
