# Copy Home Manager apps into ~/Applications so Spotlight finds them. Home
# Manager only defaults to this from stateVersion 25.11; helios pins 24.11.
{
  flake.modules.darwin.base.home-manager.sharedModules = [
    {
      targets.darwin.copyApps.enable = true;
      targets.darwin.linkApps.enable = false;
    }
  ];
}
