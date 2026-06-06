{ ... }:
{
  hosts."nixos-machine" = {
    platform = "nixos";
    system = "x86_64-linux";
    stateVersion = "25.05";
    activeUsers = [ "ety" ];
  };
}
