{ ... }:
{
  flake.modules.darwin.window-manager =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ rectangle ];
    };
}
