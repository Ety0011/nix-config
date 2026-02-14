{ pkgs, vars, ... }:
# This act as a host-specific configuration. For example you may want to enable docker only on a certain machine
{
  # 1. Host-Specific Packages (e.g. Work tools vs Personal tools)
  environment.systemPackages = with pkgs; [
    vim # IDEA: I suggest moving it to a home-manager package (you can check my neovim.nix in my nix-darwin config)
    colima
    docker
    docker-compose
  ];

  system.stateVersion = vars.stateVersion;
}
