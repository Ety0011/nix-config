{ pkgs, hostVars, ... }:
{
  environment.systemPackages = with pkgs; [
    colima
    docker
    docker-compose
  ];
  system.stateVersion = hostVars.stateVersion;
}
