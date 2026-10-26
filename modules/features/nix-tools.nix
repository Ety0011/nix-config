{
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
